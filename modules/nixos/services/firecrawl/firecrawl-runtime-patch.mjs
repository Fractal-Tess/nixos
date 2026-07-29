import { createHash, randomUUID } from "node:crypto";
import { rename, readFile, rm, writeFile } from "node:fs/promises";
import process from "node:process";

const expectedBuildSha = "ab033afd95b6e7865cf8d955fec359043389f227";
const appRoot = process.env.FIRECRAWL_APP_ROOT ?? "/app";
const enginesPath = `${appRoot}/dist/src/scraper/scrapeURL/engines/index.js`;
const playwrightPath = `${appRoot}/dist/src/scraper/scrapeURL/engines/playwright/index.js`;
const scrapePath = `${appRoot}/dist/src/scraper/scrapeURL/index.js`;
const searchIndexPath = `${appRoot}/dist/src/search/v2/index.js`;
const searxngPath = `${appRoot}/dist/src/search/v2/searxng.js`;
const agentStatusPath = `${appRoot}/dist/src/controllers/v2/agent-status.js`;
const agentCancelPath = `${appRoot}/dist/src/controllers/v2/agent-cancel.js`;
const imageAnalyzePath = `${appRoot}/dist/src/controllers/v2/image-analyze.js`;
const routesV2Path = `${appRoot}/dist/src/routes/v2.js`;
const runtimePatchesRoot = process.env.FIRECRAWL_RUNTIME_PATCHES_ROOT ?? "/opt/firecrawl/runtime-patches";

const originalHashes = {
  engines: "07a8464451a606623f9d2d5f0f49e2437fd87000c91b5cb31173211c560c2165",
  playwright: "f1b04431933831a6aa164a9d58e9e32426952ac103bb291b7f513444c99d6df7",
  scrape: "d246af8d7bea22bdd957db76beb8909fc554a3645f66b620a9b32e1f369d70d9",
  searchIndex: "8decfa3ba3f7173f126473f5e12f12a6284678408313aa9d852a67d2b3e532d7",
  searxng: "17cbe25e38d7adeac00c4c56106afe6db723481148d868cdace64747afd6687e",
  agentStatus: "580499b035f58728f8c1fa4ef951348a5bdb459899d4e1b20baa4e7b02f9cf46",
  agentCancel: "c1e95663f535f45927047ff0227d61982e4141d0db182a6fbcb9e4d31576b8b4",
  routesV2: "f8551df9ddebd894f93caff686fdbddbd18575a2c35e98d6a7fc365803631c33",
};

const originalPlaywrightFeatures = `    playwright: {
        features: {
            actions: false,
            waitFor: true,
            screenshot: false,
            "screenshot@fullScreen": false,`;
const patchedPlaywrightFeatures = `    playwright: {
        features: {
            actions: true,
            waitFor: true,
            screenshot: true,
            "screenshot@fullScreen": true,`;

const originalActionsCheck = `        // Check if actions are requested but no engines support them
        if (meta.featureFlags.has("actions")) {`;
const patchedActionsCheck = `        // The Camoufox bridge supports browser actions except Firefox-incompatible PDF output.
        if (meta.options.actions?.some(action => action.type === "pdf")) {
            throw new error_2.ActionsNotSupportedError("PDF actions are unavailable with the Camoufox engine.");
        }
        // Check if actions are requested but no engines support them
        if (meta.featureFlags.has("actions")) {`;

const patchedPlaywrightAdapter = `"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.scrapeURLWithPlaywright = scrapeURLWithPlaywright;
exports.playwrightMaxReasonableTime = playwrightMaxReasonableTime;
const zod_1 = require("zod");
const config_1 = require("../../../../config");
const fetch_1 = require("../../lib/fetch");
const firecrawl_rs_1 = require("@mendable/firecrawl-rs");
function getScreenshotFormat(formats) {
    return formats?.find(format => format?.type === "screenshot");
}
async function scrapeURLWithPlaywright(meta) {
    const screenshotFormat = getScreenshotFormat(meta.options.formats);
    const response = await (0, fetch_1.robustFetch)({
        url: config_1.config.PLAYWRIGHT_MICROSERVICE_URL,
        headers: {
            "Content-Type": "application/json",
        },
        body: {
            url: meta.rewrittenUrl ?? meta.url,
            wait_after_load: meta.options.waitFor,
            timeout: meta.abort.scrapeTimeout(),
            headers: meta.options.headers,
            skip_tls_verification: meta.options.skipTlsVerification,
            actions: meta.options.actions,
            screenshot: screenshotFormat
                ? {
                    fullPage: screenshotFormat.fullPage ?? false,
                    quality: screenshotFormat.quality,
                    viewport: screenshotFormat.viewport,
                }
                : undefined,
        },
        method: "POST",
        logger: meta.logger.child("scrapeURLWithPlaywright/robustFetch"),
        schema: zod_1.z.object({
            content: zod_1.z.string(),
            pageStatusCode: zod_1.z.number(),
            pageError: zod_1.z.string().optional(),
            contentType: zod_1.z.string().optional(),
            url: zod_1.z.string().optional(),
            screenshot: zod_1.z.string().optional(),
            actions: zod_1.z.object({
                screenshots: zod_1.z.array(zod_1.z.string()).optional(),
                scrapes: zod_1.z.array(zod_1.z.object({
                    url: zod_1.z.string(),
                    html: zod_1.z.string(),
                })).optional(),
                javascriptReturns: zod_1.z.array(zod_1.z.object({
                    type: zod_1.z.string(),
                    value: zod_1.z.any(),
                })).optional(),
                pdfs: zod_1.z.array(zod_1.z.string()).optional(),
            }).optional(),
        }),
        mock: meta.mock,
        abort: meta.abort.asSignal(),
    });
    if (response.contentType?.includes("application/json")) {
        response.content = await (0, firecrawl_rs_1.getInnerJson)(response.content);
    }
    return {
        url: response.url ?? meta.rewrittenUrl ?? meta.url,
        html: response.content,
        statusCode: response.pageStatusCode,
        error: response.pageError,
        contentType: response.contentType,
        screenshot: response.screenshot,
        actions: response.actions,
        proxyUsed: "basic",
    };
}
function playwrightMaxReasonableTime(meta) {
    const actionWait = meta.options.actions?.reduce((total, action) => action.type === "wait" ? total + (action.milliseconds ?? 1000) : total, 0) ?? 0;
    const actionOverhead = (meta.options.actions?.length ?? 0) * 2000;
    return (meta.options.waitFor ?? 0) + actionWait + actionOverhead + 30000;
}
`;

function sha256(value) {
  return createHash("sha256").update(value).digest("hex");
}

async function atomicWrite(path, content) {
  const temporaryPath = `${path}.${randomUUID()}.tmp`;
  try {
    await writeFile(temporaryPath, content);
    await rename(temporaryPath, path);
  } finally {
    await rm(temporaryPath, { force: true });
  }
}

async function patchByReplacement({ path, originalHash, original, patched }) {
  const source = await readFile(path, "utf8");
  if (source.includes(patched)) {
    const restored = source.replace(patched, original);
    if (sha256(restored) !== originalHash) {
      throw new Error(`Refusing to accept an unknown pre-patched file at ${path}`);
    }
    return;
  }
  if (sha256(source) !== originalHash || !source.includes(original)) {
    throw new Error(`Refusing to patch an unknown Firecrawl runtime file at ${path}`);
  }
  await atomicWrite(path, source.replace(original, patched));
}

async function patchPlaywrightAdapter() {
  const source = await readFile(playwrightPath, "utf8");
  const patchedHash = sha256(patchedPlaywrightAdapter);
  if (sha256(source) === patchedHash) return;
  if (sha256(source) !== originalHashes.playwright) {
    throw new Error(`Refusing to replace an unknown Playwright adapter at ${playwrightPath}`);
  }
  await atomicWrite(playwrightPath, patchedPlaywrightAdapter);
}

async function replaceWithRuntimePatch(path, originalHash, patchName) {
  const [source, patched] = await Promise.all([
    readFile(path, "utf8"),
    readFile(`${runtimePatchesRoot}/${patchName}`, "utf8"),
  ]);
  if (sha256(source) === sha256(patched)) return;
  if (sha256(source) !== originalHash) {
    throw new Error(`Refusing to replace an unknown Firecrawl runtime file at ${path}`);
  }
  await atomicWrite(path, patched);
}

async function installRuntimePatch(path, patchName) {
  const patched = await readFile(`${runtimePatchesRoot}/${patchName}`, "utf8");
  try {
    const source = await readFile(path, "utf8");
    if (sha256(source) !== sha256(patched)) {
      throw new Error(`Refusing to overwrite an unknown generated runtime file at ${path}`);
    }
  } catch (error) {
    if (error?.code !== "ENOENT") throw error;
    await atomicWrite(path, patched);
  }
}

if (process.env.FIRECRAWL_BUILD_SHA !== expectedBuildSha) {
  throw new Error(
    `Unsupported Firecrawl build ${process.env.FIRECRAWL_BUILD_SHA ?? "<unset>"}; expected ${expectedBuildSha}`,
  );
}

await patchByReplacement({
  path: enginesPath,
  originalHash: originalHashes.engines,
  original: originalPlaywrightFeatures,
  patched: patchedPlaywrightFeatures,
});
await patchByReplacement({
  path: scrapePath,
  originalHash: originalHashes.scrape,
  original: originalActionsCheck,
  patched: patchedActionsCheck,
});
await patchPlaywrightAdapter();
await replaceWithRuntimePatch(searchIndexPath, originalHashes.searchIndex, "search-v2-index.js");
await replaceWithRuntimePatch(searxngPath, originalHashes.searxng, "search-v2-searxng.js");
await replaceWithRuntimePatch(agentStatusPath, originalHashes.agentStatus, "agent-status.js");
await replaceWithRuntimePatch(agentCancelPath, originalHashes.agentCancel, "agent-cancel.js");
await replaceWithRuntimePatch(routesV2Path, originalHashes.routesV2, "routes-v2.js");
await installRuntimePatch(imageAnalyzePath, "image-analyze.js");
console.log("Enabled Camoufox actions, local agent, image analysis, and SearXNG image search in Firecrawl runtime");
