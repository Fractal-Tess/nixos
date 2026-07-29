import { fork } from "node:child_process";
import { createHash, randomUUID, timingSafeEqual } from "node:crypto";
import { setDefaultResultOrder } from "node:dns";
import { lookup } from "node:dns/promises";
import { cp, mkdir, readFile, readdir, rename, rm, writeFile } from "node:fs/promises";
import { get as httpGet } from "node:http";
import { get as httpsGet } from "node:https";
import { isIP } from "node:net";
import { fileURLToPath } from "node:url";
import express from "express";
import { z } from "zod";
import { buildFirecrawlToolkit, createAgent } from "./agent-core/src/index.ts";

setDefaultResultOrder("ipv4first");

const port = parsePositiveInteger(process.env.PORT, 3000, 1, 65535);
const jobDirectory = process.env.AGENT_JOB_DIR ?? "/data/jobs";
const agentSkillsDirectory = process.env.AGENT_SKILLS_DIR ?? "/data/skills";
const packagedSkillsDirectory = "/app/agent-core/src/skills/definitions";
const bridgeSecret = requiredEnvironment("AGENT_INTEROP_SECRET");
const firecrawlApiUrl = requiredEnvironment("FIRECRAWL_API_URL").replace(/\/$/, "");
const firecrawlApiKey = process.env.FIRECRAWL_API_KEY ?? "fc-local-firecrawl";
const modelBaseUrl = requiredEnvironment("OPENAI_BASE_URL").replace(/\/$/, "");
const modelApiKey = process.env.OPENAI_API_KEY ?? "local-firecrawl";
const modelName = process.env.MODEL_NAME ?? "gpt-5.4-mini";
const maxConcurrentJobs = parsePositiveInteger(process.env.MAX_CONCURRENT_AGENT_JOBS, 1, 1, 4);
const maxQueuedJobs = parsePositiveInteger(process.env.MAX_QUEUED_AGENT_JOBS, 8, 1, 64);
const maxAgentSteps = parsePositiveInteger(process.env.MAX_AGENT_STEPS, 24, 1, 100);
const agentTimeoutMs = parsePositiveInteger(process.env.AGENT_TIMEOUT_MS, 300_000, 10_000, 1_800_000);
const jobRetentionMs = parsePositiveInteger(process.env.AGENT_JOB_RETENTION_MS, 86_400_000, 60_000, 604_800_000);
const maxImageBytes = parsePositiveInteger(process.env.MAX_IMAGE_BYTES, 8 * 1024 * 1024, 1024, 32 * 1024 * 1024);
const maxImagesPerRequest = parsePositiveInteger(process.env.MAX_IMAGES_PER_REQUEST, 4, 1, 12);
const imageAnalysisTimeoutMs = parsePositiveInteger(process.env.IMAGE_ANALYSIS_TIMEOUT_MS, 120_000, 5_000, 600_000);

if (process.argv.includes("--syntax-check")) process.exit(0);

const requestSchema = z.object({
  id: z.string().uuid(),
  prompt: z.string().trim().min(1).max(50_000),
  urls: z.array(z.string().url()).max(20).optional(),
  schema: z.record(z.unknown()).optional(),
  model: z.enum(["spark-1-mini", "spark-1-pro"]).optional(),
  maxCredits: z.number().finite().positive().max(100_000).optional(),
  strictConstrainToURLs: z.boolean().optional(),
  webhook: z.unknown().optional(),
});

const imageInputSchema = z.object({
  url: z.string().min(1).max(16_000),
  prompt: z.string().trim().min(1).max(20_000).optional(),
  modes: z.array(z.enum(["ocr", "caption", "tags", "details"])).max(4).optional(),
});

const imageBatchSchema = z.object({
  images: z.array(imageInputSchema).min(1).max(maxImagesPerRequest),
});

const pageImagesSchema = z.object({
  url: z.string().url(),
  onlyMainContent: z.boolean().optional(),
  analyze: z.boolean().optional(),
  maxImages: z.number().int().min(1).max(maxImagesPerRequest).optional(),
  prompt: z.string().trim().min(1).max(20_000).optional(),
  modes: z.array(z.enum(["ocr", "caption", "tags", "details"])).max(4).optional(),
});

type JobStatus = "queued" | "processing" | "completed" | "failed" | "cancelled";
type JobRequest = z.infer<typeof requestSchema>;
type ImageInput = z.infer<typeof imageInputSchema>;

interface JobRecord {
  id: string;
  status: JobStatus;
  request: JobRequest;
  createdAt: string;
  updatedAt: string;
  expiresAt: string;
  data?: unknown;
  error?: string;
  model: "spark-1-mini" | "spark-1-pro";
}

const jobs = new Map<string, JobRecord>();
const queuedJobIds: string[] = [];
const activeChildren = new Map<string, ReturnType<typeof fork>>();
let activeJobs = 0;

function requiredEnvironment(name: string) {
  const value = process.env[name]?.trim();
  if (!value) throw new Error(`${name} is required`);
  return value;
}

function parsePositiveInteger(value: string | undefined, fallback: number, minimum: number, maximum: number) {
  if (value === undefined) return fallback;
  const parsed = Number(value);
  if (!Number.isInteger(parsed) || parsed < minimum || parsed > maximum) {
    throw new Error(`Expected an integer from ${minimum} to ${maximum}, received ${value}`);
  }
  return parsed;
}

function authorized(value: string | undefined) {
  if (!value?.startsWith("Bearer ")) return false;
  const supplied = Buffer.from(value.slice(7));
  const expected = Buffer.from(bridgeSecret);
  return supplied.length === expected.length && timingSafeEqual(supplied, expected);
}

function jobPath(id: string) {
  return `${jobDirectory}/${id}.json`;
}

async function atomicJsonWrite(path: string, value: unknown) {
  const temporaryPath = `${path}.${randomUUID()}.tmp`;
  try {
    await writeFile(temporaryPath, JSON.stringify(value));
    await rename(temporaryPath, path);
  } finally {
    await rm(temporaryPath, { force: true });
  }
}

async function saveJob(job: JobRecord) {
  job.updatedAt = new Date().toISOString();
  jobs.set(job.id, job);
  await atomicJsonWrite(jobPath(job.id), job);
}

async function initializeSkills() {
  await mkdir(agentSkillsDirectory, { recursive: true });
  if ((await readdir(agentSkillsDirectory)).length === 0) {
    await cp(packagedSkillsDirectory, agentSkillsDirectory, { recursive: true });
  }
}

async function loadJobs() {
  await mkdir(jobDirectory, { recursive: true });
  for (const entry of await readdir(jobDirectory)) {
    if (!/^[0-9a-f-]{36}\.json$/i.test(entry)) continue;
    try {
      const parsed = JSON.parse(await readFile(`${jobDirectory}/${entry}`, "utf8")) as JobRecord;
      if (Date.parse(parsed.expiresAt) <= Date.now()) {
        await rm(`${jobDirectory}/${entry}`, { force: true });
        continue;
      }
      if (parsed.status === "processing") {
        parsed.status = "failed";
        parsed.error = "Agent service restarted while the job was running.";
      }
      jobs.set(parsed.id, parsed);
      if (parsed.status === "queued") queuedJobIds.push(parsed.id);
      await saveJob(parsed);
    } catch (error) {
      console.error(`Ignoring invalid agent job file ${entry}`, error);
    }
  }
}

async function removeExpiredJobs() {
  const now = Date.now();
  for (const [id, job] of jobs) {
    if (Date.parse(job.expiresAt) > now || activeChildren.has(id)) continue;
    jobs.delete(id);
    const queueIndex = queuedJobIds.indexOf(id);
    if (queueIndex >= 0) queuedJobIds.splice(queueIndex, 1);
    await rm(jobPath(id), { force: true });
  }
}

function publicJob(job: JobRecord) {
  return {
    success: true,
    status: job.status === "cancelled" ? "failed" : job.status,
    ...(job.error ? { error: job.error } : {}),
    ...(job.status === "completed" ? { data: job.data } : {}),
    model: job.model,
    localModel: modelName,
    expiresAt: job.expiresAt,
  };
}

function normalizeAgentData(value: unknown) {
  if (typeof value !== "string") return value;
  try {
    return JSON.parse(value);
  } catch {
    return value;
  }
}

function errorMessage(error: unknown) {
  if (!(error instanceof Error)) return String(error);
  const cause = error.cause;
  return cause instanceof Error ? `${error.message}: ${cause.message}` : error.message;
}

async function executeWorker(jobFile: string) {
  const job = JSON.parse(await readFile(jobFile, "utf8")) as JobRecord;
  const baseToolkit = buildFirecrawlToolkit(firecrawlApiKey, {
    apiUrl: firecrawlApiUrl,
    interact: false,
  });

  const imageTools = {
    analyzeImage: {
      description: "Download and analyze one public image. Returns OCR text, a caption, semantic tags, and visual details.",
      inputSchema: imageInputSchema,
      execute: async (input: ImageInput) => analyzeImage(input),
    },
    extractPageImages: {
      description: "Extract image URLs from a rendered web page, optionally analyzing a bounded number of them.",
      inputSchema: pageImagesSchema,
      execute: async (input: z.infer<typeof pageImagesSchema>) => extractPageImages(input),
    },
  };

  const toolkit = {
    ...baseToolkit,
    tools: { ...baseToolkit.tools, ...imageTools },
    systemPrompt: `${baseToolkit.systemPrompt ?? ""}\nImage search is available by requesting the images search source. Use analyzeImage for OCR or semantic understanding, and extractPageImages for images embedded in a page. Persistent interact sessions are unavailable.`.trim(),
    createFiltered: (enabled?: string[]) => {
      const base = baseToolkit.createFiltered?.(enabled) ?? baseToolkit.tools;
      return {
        ...base,
        ...(!enabled || enabled.includes("analyzeImage") ? { analyzeImage: imageTools.analyzeImage } : {}),
        ...(!enabled || enabled.includes("extractPageImages") ? { extractPageImages: imageTools.extractPageImages } : {}),
      };
    },
  };

  const agent = createAgent({
    firecrawlApiKey,
    model: {
      provider: "openai",
      model: modelName,
      apiKey: modelApiKey,
      baseURL: modelBaseUrl,
    },
    apiKeys: { openai: modelApiKey },
    firecrawlOptions: { apiUrl: firecrawlApiUrl, interact: false },
    toolkit,
    skillsDir: agentSkillsDirectory,
    maxSteps: maxAgentSteps,
    maxWorkers: 2,
    workerMaxSteps: 8,
  });

  const result = await agent.run({
    prompt: job.request.prompt,
    urls: job.request.urls,
    schema: job.request.schema,
    format: job.request.schema ? "json" : "markdown",
    maxSteps: maxAgentSteps,
  });
  if (result.schemaMismatch) {
    throw new Error(`Agent output did not match the requested schema (missing: ${result.schemaMismatch.missing.join(", ") || "none"}; extra: ${result.schemaMismatch.extra.join(", ") || "none"}).`);
  }
  return normalizeAgentData(result.data ?? result.text);
}

async function workerMain(jobFile: string) {
  try {
    return { ok: true, data: await executeWorker(jobFile) };
  } catch (error) {
    return { ok: false, error: errorMessage(error) };
  }
}

async function startJob(job: JobRecord) {
  activeJobs += 1;
  job.status = "processing";
  delete job.error;
  await saveJob(job);

  const child = fork(fileURLToPath(import.meta.url), ["--worker", jobPath(job.id)], {
    env: process.env,
    execArgv: process.execArgv,
    stdio: ["ignore", "pipe", "pipe", "ipc"],
  });
  activeChildren.set(job.id, child);
  child.stdout?.on("data", chunk => process.stdout.write(`[agent:${job.id}] ${chunk}`));
  child.stderr?.on("data", chunk => process.stderr.write(`[agent:${job.id}] ${chunk}`));

  let settled = false;
  let pendingResult: { status: JobStatus; data?: unknown; error?: string } | undefined;
  const settleAfterExit = async (code: number | null, signal: NodeJS.Signals | null) => {
    if (settled) return;
    settled = true;
    clearTimeout(timeout);
    activeChildren.delete(job.id);
    activeJobs -= 1;
    const latest = jobs.get(job.id);
    const result = pendingResult ?? {
      status: "failed" as const,
      error: `Agent worker exited unexpectedly (${signal ?? code ?? "unknown"}).`,
    };
    if (latest?.status === "cancelled") {
      await saveJob(latest);
    } else if (latest) {
      latest.status = result.status;
      latest.data = result.data;
      latest.error = result.error;
      await saveJob(latest);
    }
    scheduleJobs();
  };

  const timeout = setTimeout(() => {
    pendingResult ??= { status: "failed", error: `Agent exceeded the ${agentTimeoutMs}ms deadline.` };
    child.kill("SIGTERM");
    setTimeout(() => child.kill("SIGKILL"), 5_000).unref();
  }, agentTimeoutMs);
  timeout.unref();

  child.once("message", message => {
    const result = message as { ok?: boolean; data?: unknown; error?: string };
    pendingResult ??= { status: result.ok ? "completed" : "failed", data: result.data, error: result.error };
    child.kill("SIGTERM");
  });
  child.once("exit", (code, signal) => void settleAfterExit(code, signal));
}

function scheduleJobs() {
  while (activeJobs < maxConcurrentJobs && queuedJobIds.length > 0) {
    const id = queuedJobIds.shift();
    if (!id) break;
    const job = jobs.get(id);
    if (job?.status === "queued") void startJob(job);
  }
}

function isPrivateAddress(address: string) {
  if (isIP(address) === 4) {
    const parts = address.split(".").map(Number);
    const value = ((parts[0] << 24) >>> 0) + (parts[1] << 16) + (parts[2] << 8) + parts[3];
    const inRange = (base: number, bits: number) => (value >>> (32 - bits)) === (base >>> (32 - bits));
    return inRange(0x00000000, 8) || inRange(0x0a000000, 8) || inRange(0x64400000, 10) ||
      inRange(0x7f000000, 8) || inRange(0xa9fe0000, 16) || inRange(0xac100000, 12) ||
      inRange(0xc0000000, 24) || inRange(0xc0000200, 24) || inRange(0xc0a80000, 16) ||
      inRange(0xc6120000, 15) || inRange(0xc6336400, 24) || inRange(0xcb007100, 24) ||
      inRange(0xe0000000, 4) || inRange(0xf0000000, 4);
  }
  const normalized = address.toLowerCase();
  return normalized.startsWith("::") || normalized.startsWith("fc") || normalized.startsWith("fd") ||
    /^fe[89a-f]/.test(normalized) || normalized.startsWith("ff") || normalized.startsWith("64:ff9b:") ||
    normalized.startsWith("100:") || normalized.startsWith("2001:0:") || normalized.startsWith("2001:2:") ||
    normalized.startsWith("2001:10:") || normalized.startsWith("2001:20:") || normalized.startsWith("2001:db8:") ||
    normalized.startsWith("2002:");
}

async function validatePublicUrl(value: string) {
  const url = new URL(value);
  if (url.protocol !== "http:" && url.protocol !== "https:") throw new Error("Only HTTP(S) image URLs are allowed.");
  if (url.username || url.password) throw new Error("Image URLs may not contain credentials.");
  const addresses = await lookup(url.hostname, { all: true, verbatim: true });
  if (addresses.length === 0 || addresses.some(result => isPrivateAddress(result.address))) {
    throw new Error("Image URL resolves to a private or reserved address.");
  }
  const address = addresses.find(result => result.family === 4) ?? addresses[0];
  return { url, address };
}

function requestImage(target: Awaited<ReturnType<typeof validatePublicUrl>>, signal: AbortSignal) {
  return new Promise<import("node:http").IncomingMessage>((resolve, reject) => {
    const get = target.url.protocol === "https:" ? httpsGet : httpGet;
    const request = get(target.url, {
      headers: { "User-Agent": "Firecrawl-Image-Analyzer/1.0" },
      servername: target.url.hostname,
      signal,
      lookup: (_hostname, options, callback) => {
        if (typeof options === "object" && options.all) callback(null, [target.address]);
        else callback(null, target.address.address, target.address.family);
      },
    }, resolve);
    request.once("error", reject);
    request.setTimeout(30_000, () => request.destroy(new Error("Image download timed out.")));
  });
}

function sniffImageType(buffer: Buffer) {
  if (buffer.subarray(0, 8).equals(Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]))) return "image/png";
  if (buffer.subarray(0, 3).equals(Buffer.from([0xff, 0xd8, 0xff]))) return "image/jpeg";
  if (buffer.subarray(0, 6).toString("ascii") === "GIF87a" || buffer.subarray(0, 6).toString("ascii") === "GIF89a") return "image/gif";
  if (buffer.subarray(0, 4).toString("ascii") === "RIFF" && buffer.subarray(8, 12).toString("ascii") === "WEBP") return "image/webp";
  throw new Error("Downloaded content is not a supported PNG, JPEG, GIF, or WebP image.");
}

async function downloadImage(value: string, signal: AbortSignal) {
  if (value.startsWith("data:image/")) {
    const match = /^data:(image\/(?:png|jpeg|gif|webp));base64,([a-z0-9+/=]+)$/i.exec(value);
    if (!match) throw new Error("Only base64 PNG, JPEG, GIF, and WebP data URIs are allowed.");
    const buffer = Buffer.from(match[2], "base64");
    if (buffer.length > maxImageBytes) throw new Error("Image exceeds the configured byte limit.");
    return { buffer, mimeType: sniffImageType(buffer), sourceUrl: "data-uri" };
  }

  let current = await validatePublicUrl(value);
  for (let redirect = 0; redirect <= 4; redirect += 1) {
    const response = await requestImage(current, signal);
    const status = response.statusCode ?? 0;
    if ([301, 302, 303, 307, 308].includes(status)) {
      response.destroy();
      const location = response.headers.location;
      if (!location || redirect === 4) throw new Error("Too many image redirects.");
      current = await validatePublicUrl(new URL(location, current.url).href);
      continue;
    }
    if (status < 200 || status >= 300) {
      response.destroy();
      throw new Error(`Image download failed with HTTP ${status}.`);
    }
    const declaredLength = Number(response.headers["content-length"] ?? 0);
    if (declaredLength > maxImageBytes) {
      response.destroy();
      throw new Error("Image exceeds the configured byte limit.");
    }
    const chunks: Buffer[] = [];
    let length = 0;
    for await (const chunk of response) {
      const buffer = Buffer.from(chunk);
      length += buffer.length;
      if (length > maxImageBytes) {
        response.destroy();
        throw new Error("Image exceeds the configured byte limit.");
      }
      chunks.push(buffer);
    }
    const buffer = Buffer.concat(chunks);
    return { buffer, mimeType: sniffImageType(buffer), sourceUrl: current.url.href };
  }
  throw new Error("Image download failed.");
}

function parseModelJson(value: string) {
  const fenced = /```(?:json)?\s*([\s\S]*?)```/i.exec(value)?.[1] ?? value;
  try {
    return JSON.parse(fenced.trim());
  } catch {
    return { text: value };
  }
}

async function analyzeImage(input: ImageInput) {
  const signal = AbortSignal.timeout(imageAnalysisTimeoutMs);
  const image = await downloadImage(input.url, signal);
  const modes = input.modes?.length ? input.modes : ["ocr", "caption", "tags", "details"];
  const requestedPrompt = input.prompt ?? "Analyze this image accurately.";
  const response = await fetch(`${modelBaseUrl}/chat/completions`, {
    method: "POST",
    signal,
    headers: { "Content-Type": "application/json", Authorization: `Bearer ${modelApiKey}` },
    body: JSON.stringify({
      model: modelName,
      messages: [{
        role: "user",
        content: [
          { type: "text", text: `${requestedPrompt}\nReturn only JSON. Requested fields: ${modes.join(", ")}. Use keys ocrText, caption, tags, and details when requested. Never invent unreadable text.` },
          { type: "image_url", image_url: { url: `data:${image.mimeType};base64,${image.buffer.toString("base64")}` } },
        ],
      }],
      max_tokens: 2048,
    }),
  });
  const body = await response.json() as { choices?: Array<{ message?: { content?: string | Array<{ text?: string }> } }>; error?: { message?: string } };
  if (!response.ok) throw new Error(body.error?.message ?? `Image model failed with HTTP ${response.status}.`);
  const content = body.choices?.[0]?.message?.content;
  const text = typeof content === "string" ? content : content?.map(part => part.text ?? "").join("") ?? "";
  if (!text) throw new Error("Image model returned no content.");
  return {
    sourceUrl: image.sourceUrl,
    mimeType: image.mimeType,
    bytes: image.buffer.length,
    sha256: createHash("sha256").update(image.buffer).digest("hex"),
    analysis: parseModelJson(text),
  };
}

async function extractPageImages(input: z.infer<typeof pageImagesSchema>) {
  const response = await fetch(`${firecrawlApiUrl}/v2/scrape`, {
    method: "POST",
    headers: { "Content-Type": "application/json", Authorization: `Bearer ${firecrawlApiKey}` },
    body: JSON.stringify({ url: input.url, formats: ["images"], onlyMainContent: input.onlyMainContent ?? false, maxAge: 0 }),
  });
  const body = await response.json() as { success?: boolean; data?: { images?: string[] }; error?: string };
  if (!response.ok || !body.success) throw new Error(body.error ?? `Firecrawl image extraction failed with HTTP ${response.status}.`);
  const allImages = body.data?.images ?? [];
  const images = allImages.slice(0, input.maxImages ?? maxImagesPerRequest);
  if (!input.analyze) return { images };
  const analyses = await Promise.all(images.map(async url => {
    try {
      return await analyzeImage({ url, prompt: input.prompt, modes: input.modes });
    } catch (error) {
      return { sourceUrl: url, error: errorMessage(error) };
    }
  }));
  return { images, analyses };
}

if (process.argv[2] === "--worker") {
  const workerFile = process.argv[3];
  if (!workerFile) throw new Error("Worker job file is required.");
  const result = await workerMain(workerFile);
  if (process.send) {
    await new Promise<void>(resolve => process.send?.(result, () => resolve()));
  }
  process.exit(result.ok ? 0 : 1);
}

await Promise.all([initializeSkills(), loadJobs()]);
const expiryTimer = setInterval(() => void removeExpiredJobs().catch(error => console.error("Agent job expiry cleanup failed", error)), 60_000);
expiryTimer.unref();

const app = express();
app.disable("x-powered-by");
app.use(express.json({ limit: "1mb" }));
app.use((req, res, next) => {
  if (req.path === "/" || req.path === "/health") return next();
  if (!authorized(req.header("authorization"))) return res.status(401).json({ success: false, error: "Unauthorized" });
  next();
});

app.get("/", (_req, res) => {
  res.json({ status: "ok", model: modelName, queued: queuedJobIds.length, active: activeJobs });
});

app.get("/health", async (_req, res) => {
  try {
    const signal = AbortSignal.timeout(4_000);
    const [firecrawl, model] = await Promise.all([
      fetch(firecrawlApiUrl, { signal }),
      fetch(`${modelBaseUrl}/models`, { signal, headers: { Authorization: `Bearer ${modelApiKey}` } }),
    ]);
    if (!firecrawl.ok || !model.ok) throw new Error(`Dependency status: Firecrawl ${firecrawl.status}, model proxy ${model.status}`);
    res.json({ status: "ok", model: modelName, queued: queuedJobIds.length, active: activeJobs });
  } catch (error) {
    res.status(503).json({ status: "unavailable", error: errorMessage(error) });
  }
});

app.post("/internal/extracts", async (req, res) => {
  const parsed = requestSchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ success: false, error: parsed.error.issues.map(issue => issue.message).join("; ") });
  if (jobs.has(parsed.data.id)) return res.status(409).json({ success: false, error: "Agent job already exists" });
  if (parsed.data.strictConstrainToURLs) return res.status(400).json({ success: false, error: "strictConstrainToURLs is not supported by the local agent" });
  if (parsed.data.webhook !== undefined) return res.status(400).json({ success: false, error: "Agent webhooks are not supported by the local agent" });
  if (parsed.data.maxCredits !== undefined) return res.status(400).json({ success: false, error: "maxCredits is not supported by the local agent" });
  if (queuedJobIds.length >= maxQueuedJobs) return res.status(429).json({ success: false, error: "Agent queue is full" });
  for (const url of parsed.data.urls ?? []) {
    const validated = new URL(url);
    if (validated.protocol !== "http:" && validated.protocol !== "https:") return res.status(400).json({ success: false, error: "Agent URLs must use HTTP(S)" });
  }
  const now = new Date();
  const job: JobRecord = {
    id: parsed.data.id,
    status: "queued",
    request: parsed.data,
    createdAt: now.toISOString(),
    updatedAt: now.toISOString(),
    expiresAt: new Date(now.getTime() + jobRetentionMs).toISOString(),
    model: parsed.data.model ?? "spark-1-mini",
  };
  jobs.set(job.id, job);
  queuedJobIds.push(job.id);
  try {
    await saveJob(job);
  } catch (error) {
    jobs.delete(job.id);
    const queueIndex = queuedJobIds.indexOf(job.id);
    if (queueIndex >= 0) queuedJobIds.splice(queueIndex, 1);
    throw error;
  }
  scheduleJobs();
  return res.json({ success: true, id: job.id });
});

app.get("/internal/extracts/:id", (req, res) => {
  const job = jobs.get(req.params.id);
  if (!job) return res.status(404).json({ success: false, error: "Agent job not found" });
  return res.json(publicJob(job));
});

app.get("/v2/extract/:id/options", (req, res) => {
  const job = jobs.get(req.params.id);
  if (!job) return res.status(404).json({ success: false, error: "Agent job not found" });
  return res.json({ model: job.model });
});

app.delete("/internal/extracts/:id", async (req, res) => {
  const job = jobs.get(req.params.id);
  if (!job) return res.status(404).json({ success: false, error: "Agent job not found" });
  if (["completed", "failed", "cancelled"].includes(job.status)) return res.status(409).json({ success: false, error: "Agent already finished" });
  job.status = "cancelled";
  job.error = "Agent job was cancelled.";
  const queuedIndex = queuedJobIds.indexOf(job.id);
  if (queuedIndex >= 0) queuedJobIds.splice(queuedIndex, 1);
  activeChildren.get(job.id)?.kill("SIGTERM");
  await saveJob(job);
  return res.json({ success: true });
});

app.post("/v1/images/analyze", async (req, res) => {
  const parsed = imageBatchSchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ success: false, error: parsed.error.issues.map(issue => issue.message).join("; ") });
  const results = await Promise.all(parsed.data.images.map(async image => {
    try {
      return await analyzeImage(image);
    } catch (error) {
      return { sourceUrl: image.url, error: errorMessage(error) };
    }
  }));
  return res.json({ success: true, data: { images: results } });
});

app.post("/v1/images/from-page", async (req, res) => {
  const parsed = pageImagesSchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ success: false, error: parsed.error.issues.map(issue => issue.message).join("; ") });
  try {
    return res.json({ success: true, data: await extractPageImages(parsed.data) });
  } catch (error) {
    return res.status(502).json({ success: false, error: errorMessage(error) });
  }
});

app.use((error: unknown, _req, res, _next) => {
  console.error("Agent service request failed", error);
  res.status(500).json({ success: false, error: errorMessage(error) });
});

const server = app.listen(port, "0.0.0.0", () => {
  console.log(`Firecrawl local agent listening on ${port}`);
  scheduleJobs();
});

for (const signal of ["SIGTERM", "SIGINT"] as const) {
  process.on(signal, () => {
    server.close(() => process.exit(0));
    setTimeout(() => process.exit(1), 10_000).unref();
  });
}
