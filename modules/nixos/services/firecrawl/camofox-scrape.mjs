import dns from "node:dns/promises";
import http from "node:http";
import net from "node:net";
import process from "node:process";

import { launchOptions } from "camoufox-js";
import { VirtualDisplay } from "camoufox-js/dist/virtdisplay.js";
import express from "express";
import ipaddr from "ipaddr.js";
import { firefox } from "playwright-core";

const port = Number.parseInt(process.env.PORT ?? "3000", 10);
const maxConcurrentPages = Math.max(
  1,
  Number.parseInt(process.env.MAX_CONCURRENT_PAGES ?? "3", 10) || 3,
);
const maxQueuedPages = Math.max(
  maxConcurrentPages,
  Number.parseInt(process.env.MAX_QUEUED_PAGES ?? "6", 10) || 6,
);

class AdmissionError extends Error {}

class BoundedSemaphore {
  #available;
  #queue = [];

  constructor(permits) {
    this.#available = permits;
  }

  acquire(signal) {
    if (signal.aborted) {
      return Promise.reject(signal.reason ?? new Error("Request aborted"));
    }

    if (this.#available > 0) {
      this.#available -= 1;
      return Promise.resolve(this.#createRelease());
    }

    if (this.#queue.length >= maxQueuedPages) {
      return Promise.reject(new AdmissionError("Browser queue is full"));
    }

    return new Promise((resolve, reject) => {
      const entry = { resolve, reject, signal, onAbort: undefined };
      entry.onAbort = () => {
        const index = this.#queue.indexOf(entry);
        if (index !== -1) this.#queue.splice(index, 1);
        reject(signal.reason ?? new Error("Request aborted"));
      };
      signal.addEventListener("abort", entry.onAbort, { once: true });
      this.#queue.push(entry);
    });
  }

  #createRelease() {
    let released = false;
    return () => {
      if (released) return;
      released = true;

      while (this.#queue.length > 0) {
        const entry = this.#queue.shift();
        entry.signal.removeEventListener("abort", entry.onAbort);
        if (entry.signal.aborted) continue;
        entry.resolve(this.#createRelease());
        return;
      }

      this.#available += 1;
    };
  }

  get active() {
    return maxConcurrentPages - this.#available;
  }

  get queued() {
    return this.#queue.length;
  }

  cancelQueued(reason) {
    for (const entry of this.#queue.splice(0)) {
      entry.signal.removeEventListener("abort", entry.onAbort);
      entry.reject(reason);
    }
  }
}

const semaphore = new BoundedSemaphore(maxConcurrentPages);
const activeContexts = new Set();
let browser;
let browserStart;
let virtualDisplay;
let virtualDisplayName;
let shuttingDown = false;

function isPublicAddress(address) {
  try {
    let parsed = ipaddr.parse(address);
    if (parsed.kind() === "ipv6" && parsed.isIPv4MappedAddress()) {
      parsed = parsed.toIPv4Address();
    }
    return parsed.range() === "unicast";
  } catch {
    return false;
  }
}

async function resolvePublicHost(hostname) {
  const normalizedHostname = hostname.toLowerCase().replace(/\.$/, "");
  const host =
    normalizedHostname.startsWith("[") && normalizedHostname.endsWith("]")
      ? normalizedHostname.slice(1, -1)
      : normalizedHostname;
  if (!host || host.includes("%")) {
    throw new Error(`Blocked unsafe hostname: ${hostname}`);
  }

  if (ipaddr.isValid(host)) {
    if (!isPublicAddress(host)) {
      throw new Error(`Blocked non-public address: ${host}`);
    }
    const parsed = ipaddr.parse(host);
    const normalized =
      parsed.kind() === "ipv6" && parsed.isIPv4MappedAddress()
        ? parsed.toIPv4Address()
        : parsed;
    return {
      address: normalized.toString(),
      family: normalized.kind() === "ipv4" ? 4 : 6,
    };
  }

  let addresses;
  try {
    addresses = await dns.lookup(host, { all: true, verbatim: true });
  } catch {
    throw new Error(`Blocked unresolvable hostname: ${hostname}`);
  }

  if (addresses.length === 0 || addresses.some(({ address }) => !isPublicAddress(address))) {
    throw new Error(`Blocked hostname with a non-public address: ${hostname}`);
  }

  return addresses[0];
}

function parseTargetUrl(value) {
  let parsed;
  try {
    parsed = new URL(value);
  } catch {
    throw new Error(`Invalid URL: ${value}`);
  }

  if (parsed.protocol !== "http:" && parsed.protocol !== "https:") {
    throw new Error(`Blocked URL scheme: ${parsed.protocol}`);
  }

  return parsed;
}

async function assertPublicUrl(value) {
  const parsed = parseTargetUrl(value);
  await resolvePublicHost(parsed.hostname);
  return parsed;
}

function parseConnectAuthority(authority) {
  let parsed;
  try {
    parsed = new URL(`http://${authority}`);
  } catch {
    throw new Error(`Invalid proxy target: ${authority}`);
  }

  const targetPort = Number.parseInt(parsed.port || "443", 10);
  if (!Number.isInteger(targetPort) || targetPort < 1 || targetPort > 65535) {
    throw new Error(`Invalid proxy port: ${parsed.port}`);
  }

  return { hostname: parsed.hostname, port: targetPort };
}

function filteredProxyHeaders(headers, host) {
  const blockedHeaders = new Set([
    "connection",
    "keep-alive",
    "proxy-authenticate",
    "proxy-authorization",
    "proxy-connection",
    "te",
    "trailer",
    "transfer-encoding",
    "upgrade",
  ]);
  const result = {};

  for (const [name, value] of Object.entries(headers)) {
    if (!blockedHeaders.has(name.toLowerCase()) && value !== undefined) {
      result[name] = value;
    }
  }

  result.host = host;
  return result;
}

async function createFilteringProxy() {
  const sockets = new Set();
  const blockedTargets = [];

  const markBlocked = (target, error) => {
    blockedTargets.push({ target, message: error.message });
  };

  const server = http.createServer(async (request, response) => {
    let target;
    try {
      target = parseTargetUrl(request.url);
      if (target.protocol !== "http:") {
        throw new Error(`Unexpected proxy protocol: ${target.protocol}`);
      }
      const resolved = await resolvePublicHost(target.hostname);
      const targetPort = Number.parseInt(target.port || "80", 10);
      const upstream = http.request({
        host: resolved.address,
        family: resolved.family,
        port: targetPort,
        method: request.method,
        path: `${target.pathname}${target.search}`,
        headers: filteredProxyHeaders(request.headers, target.host),
      });

      upstream.on("response", upstreamResponse => {
        response.writeHead(upstreamResponse.statusCode ?? 502, upstreamResponse.headers);
        upstreamResponse.pipe(response);
      });
      upstream.on("error", error => {
        if (!response.headersSent) response.writeHead(502);
        response.end(error.message);
      });
      request.pipe(upstream);
    } catch (error) {
      markBlocked(request.url, error);
      response.writeHead(403, { "content-type": "text/plain; charset=utf-8" });
      response.end(error.message);
    }
  });

  server.on("connect", async (request, clientSocket, head) => {
    try {
      const target = parseConnectAuthority(request.url);
      const resolved = await resolvePublicHost(target.hostname);
      const upstreamSocket = net.connect({
        host: resolved.address,
        family: resolved.family,
        port: target.port,
      });
      sockets.add(upstreamSocket);
      upstreamSocket.once("close", () => sockets.delete(upstreamSocket));
      upstreamSocket.once("connect", () => {
        clientSocket.write("HTTP/1.1 200 Connection Established\r\n\r\n");
        if (head.length > 0) upstreamSocket.write(head);
        upstreamSocket.pipe(clientSocket);
        clientSocket.pipe(upstreamSocket);
      });
      upstreamSocket.once("error", error => {
        if (!clientSocket.destroyed) {
          clientSocket.end("HTTP/1.1 502 Bad Gateway\r\n\r\n");
        }
        markBlocked(request.url, error);
      });
    } catch (error) {
      markBlocked(request.url, error);
      if (!clientSocket.destroyed) {
        clientSocket.end("HTTP/1.1 403 Forbidden\r\n\r\n");
      }
    }
  });

  server.on("upgrade", (_request, socket) => {
    socket.end("HTTP/1.1 403 Forbidden\r\n\r\n");
  });
  server.on("connection", socket => {
    sockets.add(socket);
    socket.once("close", () => sockets.delete(socket));
  });

  await new Promise((resolve, reject) => {
    server.once("error", reject);
    server.listen(0, "127.0.0.1", resolve);
  });

  const address = server.address();
  if (!address || typeof address === "string") {
    throw new Error("Failed to start filtering proxy");
  }

  return {
    url: `http://127.0.0.1:${address.port}`,
    blockedTargets,
    async close() {
      for (const socket of sockets) socket.destroy();
      if (!server.listening) return;
      await new Promise(resolve => server.close(resolve));
    },
  };
}

async function ensureBrowser() {
  if (shuttingDown) throw new Error("Browser service is shutting down");
  if (browser?.isConnected()) return browser;
  if (browserStart) return browserStart;

  browserStart = (async () => {
    if (!virtualDisplay) {
      try {
        virtualDisplay = new VirtualDisplay();
        virtualDisplayName = await virtualDisplay.get();
      } catch (error) {
        console.warn("Xvfb unavailable; using headless Camoufox", error);
        virtualDisplay = undefined;
        virtualDisplayName = undefined;
      }
    }

    const options = await launchOptions({
      executable_path: process.env.CAMOUFOX_EXECUTABLE || undefined,
      headless: !virtualDisplayName,
      os: "linux",
      humanize: true,
      enable_cache: true,
      virtual_display: virtualDisplayName,
    });
    options.handleSIGINT = false;
    options.handleSIGTERM = false;
    options.handleSIGHUP = false;

    const launched = await firefox.launch(options);
    launched.once("disconnected", () => {
      if (browser === launched) browser = undefined;
    });
    browser = launched;
    return launched;
  })().finally(() => {
    browserStart = undefined;
  });

  return browserStart;
}

function requestAbortSignal(request, response) {
  const controller = new AbortController();
  request.once("aborted", () => controller.abort(new Error("Client aborted request")));
  response.once("close", () => {
    if (!response.writableEnded) controller.abort(new Error("Client disconnected"));
  });
  return controller.signal;
}

function normalizeHeaders(headers) {
  if (headers === undefined) return undefined;
  if (headers === null || typeof headers !== "object" || Array.isArray(headers)) {
    throw new Error("headers must be an object");
  }

  return Object.fromEntries(
    Object.entries(headers).map(([name, value]) => [name, String(value)]),
  );
}

function findHeader(headers, targetName) {
  if (!headers) return undefined;
  return Object.entries(headers).find(
    ([name]) => name.toLowerCase() === targetName,
  )?.[1];
}

async function applyRequestHeaders(context, page, url, headers) {
  if (!headers) return;

  const cookieHeader = findHeader(headers, "cookie");
  if (cookieHeader) {
    const cookies = cookieHeader
      .split(";")
      .map(pair => pair.trim())
      .filter(Boolean)
      .map(pair => {
        const separator = pair.indexOf("=");
        if (separator <= 0) return undefined;
        return {
          name: pair.slice(0, separator).trim(),
          value: pair.slice(separator + 1).trim(),
          url: new URL(url).origin,
        };
      })
      .filter(Boolean);
    if (cookies.length > 0) await context.addCookies(cookies);
  }

  const blocked = new Set([
    "connection",
    "content-length",
    "cookie",
    "host",
    "proxy-authorization",
    "proxy-connection",
    "transfer-encoding",
    "user-agent",
  ]);
  const forwarded = Object.fromEntries(
    Object.entries(headers).filter(([name]) => !blocked.has(name.toLowerCase())),
  );
  if (Object.keys(forwarded).length > 0) {
    await page.setExtraHTTPHeaders(forwarded);
  }
}

function getPageError(statusCode) {
  if (statusCode < 300) return undefined;
  const messages = {
    300: "Multiple Choices",
    301: "Moved Permanently",
    302: "Found",
    303: "See Other",
    304: "Not Modified",
    305: "Use Proxy",
    307: "Temporary Redirect",
    308: "Permanent Redirect",
    400: "Bad Request",
    401: "Unauthorized",
    403: "Forbidden",
    404: "Not Found",
    405: "Method Not Allowed",
    406: "Not Acceptable",
    407: "Proxy Authentication Required",
    408: "Request Timeout",
    409: "Conflict",
    410: "Gone",
    411: "Length Required",
    412: "Precondition Failed",
    413: "Payload Too Large",
    414: "URI Too Long",
    415: "Unsupported Media Type",
    416: "Range Not Satisfiable",
    417: "Expectation Failed",
    418: "I'm a teapot",
    421: "Misdirected Request",
    422: "Unprocessable Entity",
    423: "Locked",
    424: "Failed Dependency",
    425: "Too Early",
    426: "Upgrade Required",
    428: "Precondition Required",
    429: "Too Many Requests",
    431: "Request Header Fields Too Large",
    451: "Unavailable For Legal Reasons",
    500: "Internal Server Error",
    501: "Not Implemented",
    502: "Bad Gateway",
    503: "Service Unavailable",
    504: "Gateway Timeout",
    505: "HTTP Version Not Supported",
    506: "Variant Also Negotiates",
    507: "Insufficient Storage",
    508: "Loop Detected",
    510: "Not Extended",
    511: "Network Authentication Required",
    599: "Network Connect Timeout Error",
  };
  return messages[statusCode] ?? "Unknown Error";
}

async function closeContext(context) {
  if (!context) return;
  activeContexts.delete(context);
  await Promise.race([
    context.close().catch(() => {}),
    new Promise(resolve => setTimeout(resolve, 5000)),
  ]);
}

const app = express();
app.use(express.json({ limit: "1mb" }));

app.get("/health", async (_request, response) => {
  try {
    const currentBrowser = await ensureBrowser();
    const context = await currentBrowser.newContext();
    await context.close();
    response.json({
      status: "healthy",
      engine: "camoufox",
      activePages: semaphore.active,
      queuedPages: semaphore.queued,
      maxConcurrentPages,
    });
  } catch (error) {
    response.status(503).json({ status: "unhealthy", error: error.message });
  }
});

app.post("/scrape", async (request, response) => {
  const signal = requestAbortSignal(request, response);
  let release;
  let filteringProxy;
  let context;

  try {
    const {
      url,
      wait_after_load: requestedWait = 0,
      timeout: requestedTimeout = 15000,
      headers: requestedHeaders,
      check_selector: checkSelector,
      skip_tls_verification: skipTlsVerification = false,
    } = request.body ?? {};

    if (typeof url !== "string" || url.length === 0) {
      return response.status(400).json({ error: "URL is required" });
    }

    try {
      await assertPublicUrl(url);
    } catch (error) {
      return response.json({
        content: "",
        pageStatusCode: 403,
        pageError: error.message,
      });
    }

    const waitAfterLoad = Math.max(0, Number(requestedWait) || 0);
    const timeout = Math.min(300000, Math.max(1000, Number(requestedTimeout) || 15000));
    const headers = normalizeHeaders(requestedHeaders);

    release = await semaphore.acquire(signal);
    filteringProxy = await createFilteringProxy();
    signal.throwIfAborted();

    const currentBrowser = await ensureBrowser();
    const userAgent = findHeader(headers, "user-agent");
    context = await currentBrowser.newContext({
      viewport: null,
      ignoreHTTPSErrors: Boolean(skipTlsVerification),
      serviceWorkers: "block",
      proxy: { server: filteringProxy.url },
      ...(userAgent ? { userAgent } : {}),
    });
    activeContexts.add(context);

    const page = await context.newPage();
    await applyRequestHeaders(context, page, url, headers);

    let navigationResponse;
    try {
      navigationResponse = await page.goto(url, { waitUntil: "load", timeout });
    } catch (error) {
      if (filteringProxy.blockedTargets.length > 0) {
        return response.json({
          content: "",
          pageStatusCode: 403,
          pageError: filteringProxy.blockedTargets[0].message,
        });
      }
      throw error;
    }

    signal.throwIfAborted();
    if (waitAfterLoad > 0) await page.waitForTimeout(waitAfterLoad);
    if (checkSelector) await page.waitForSelector(String(checkSelector), { timeout });

    const statusCode = navigationResponse?.status() ?? 200;
    const responseHeaders = navigationResponse ? await navigationResponse.allHeaders() : {};
    const contentType = Object.entries(responseHeaders).find(
      ([name]) => name.toLowerCase() === "content-type",
    )?.[1];

    let content = await page.content();
    if (
      navigationResponse &&
      contentType &&
      (contentType.toLowerCase().includes("application/json") ||
        contentType.toLowerCase().includes("text/plain"))
    ) {
      content = (await navigationResponse.body()).toString("utf8");
    }

    response.json({
      content,
      pageStatusCode: statusCode,
      ...(contentType ? { contentType } : {}),
      ...(getPageError(statusCode) ? { pageError: getPageError(statusCode) } : {}),
    });
  } catch (error) {
    if (error instanceof AdmissionError) {
      if (!response.headersSent) response.status(503).json({ error: error.message });
    } else if (!signal.aborted && !response.headersSent) {
      console.error("Scrape failed", error);
      response.status(500).json({ error: "An error occurred while fetching the page." });
    }
  } finally {
    await closeContext(context);
    await filteringProxy?.close().catch(() => {});
    release?.();
  }
});

const server = app.listen(port, "0.0.0.0", async () => {
  console.log(`Firecrawl Camoufox service listening on port ${port}`);
  try {
    await ensureBrowser();
  } catch (error) {
    console.error("Camoufox pre-warm failed", error);
  }
});

async function shutdown(signal) {
  if (shuttingDown) return;
  shuttingDown = true;
  console.log(`Received ${signal}; shutting down`);
  semaphore.cancelQueued(new Error("Browser service is shutting down"));
  server.close();

  await Promise.allSettled([...activeContexts].map(closeContext));
  if (browser) await browser.close().catch(() => {});
  if (virtualDisplay) virtualDisplay.kill();
  process.exit(0);
}

process.on("SIGINT", () => shutdown("SIGINT"));
process.on("SIGTERM", () => shutdown("SIGTERM"));
