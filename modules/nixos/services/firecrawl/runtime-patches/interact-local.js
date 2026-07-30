"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.interactCreateController = interactCreateController;
exports.interactListController = interactListController;
exports.interactStatusController = interactStatusController;
exports.interactExecuteController = interactExecuteController;
exports.interactDeleteController = interactDeleteController;

const sessionTokens = new Map();
const maximumResponseBytes = 1024 * 1024;

function configuration() {
    const baseUrl = process.env.CAMOFOX_INTERACT_URL;
    const secret = process.env.CAMOFOX_INTERACT_SECRET;
    if (!baseUrl || !secret) return undefined;
    return { baseUrl: baseUrl.replace(/\/$/, ""), secret };
}

async function boundedJson(response) {
    const reader = response.body?.getReader();
    if (!reader) return {};
    const chunks = [];
    let length = 0;
    while (true) {
        const { done, value } = await reader.read();
        if (done) break;
        length += value.byteLength;
        if (length > maximumResponseBytes) {
            await reader.cancel();
            throw new Error("Camoufox interact response exceeded its size limit");
        }
        chunks.push(Buffer.from(value));
    }
    const text = Buffer.concat(chunks).toString("utf8");
    try {
        return JSON.parse(text);
    }
    catch {
        return { success: false, error: text || "Camoufox interact returned an invalid response" };
    }
}

async function requestCamoufox(path, options = {}) {
    const config = configuration();
    if (!config) return { status: 503, body: { success: false, error: "Persistent interact sessions are not configured" } };
    const response = await fetch(`${config.baseUrl}${path}`, {
        ...options,
        signal: AbortSignal.timeout(120000),
        headers: {
            "Content-Type": "application/json",
            Authorization: `Bearer ${config.secret}`,
            ...options.headers,
        },
    });
    return { status: response.status, body: await boundedJson(response) };
}

function internalError(error) {
    return { success: false, error: `Persistent interact service is unavailable: ${error instanceof Error ? error.message : String(error)}` };
}

async function interactCreateController(req, res) {
    try {
        const ttlSeconds = Number(req.body?.ttl);
        const ttlMs = Number.isFinite(ttlSeconds) ? ttlSeconds * 1000 : undefined;
        const upstream = await requestCamoufox("/sessions", {
            method: "POST",
            body: JSON.stringify({ url: req.body?.url, headers: req.body?.headers, ttlMs }),
        });
        if (upstream.status >= 200 && upstream.status < 300 && upstream.body?.id && upstream.body?.token) {
            sessionTokens.set(upstream.body.id, upstream.body.token);
            const { token: _token, ...safeBody } = upstream.body;
            return res.status(upstream.status).json(safeBody);
        }
        return res.status(upstream.status).json(upstream.body);
    }
    catch (error) {
        return res.status(503).json(internalError(error));
    }
}

async function interactListController(_req, res) {
    try {
        const upstream = await requestCamoufox("/sessions");
        return res.status(upstream.status).json(upstream.body);
    }
    catch (error) {
        return res.status(503).json(internalError(error));
    }
}

async function interactStatusController(req, res) {
    const token = sessionTokens.get(req.params.sessionId);
    if (!token) return res.status(404).json({ success: false, error: "Session not found or expired" });
    try {
        const upstream = await requestCamoufox(`/sessions/${encodeURIComponent(req.params.sessionId)}`, {
            headers: { "X-Session-Token": token },
        });
        if ([404, 410].includes(upstream.status)) sessionTokens.delete(req.params.sessionId);
        return res.status(upstream.status).json(upstream.body);
    }
    catch (error) {
        return res.status(503).json(internalError(error));
    }
}

async function interactExecuteController(req, res) {
    const token = sessionTokens.get(req.params.sessionId);
    if (!token) return res.status(404).json({ success: false, error: "Session not found or expired" });
    if (req.body?.code !== undefined) {
        return res.status(400).json({ success: false, error: "Local Camoufox interact accepts bounded Firecrawl actions, not arbitrary browser code" });
    }
    try {
        const upstream = await requestCamoufox(`/sessions/${encodeURIComponent(req.params.sessionId)}/actions`, {
            method: "POST",
            headers: { "X-Session-Token": token },
            body: JSON.stringify({ actions: req.body?.actions }),
        });
        if ([404, 410].includes(upstream.status)) sessionTokens.delete(req.params.sessionId);
        return res.status(upstream.status).json(upstream.body);
    }
    catch (error) {
        return res.status(503).json(internalError(error));
    }
}

async function interactDeleteController(req, res) {
    const token = sessionTokens.get(req.params.sessionId);
    if (!token) return res.status(404).json({ success: false, error: "Session not found or expired" });
    try {
        const upstream = await requestCamoufox(`/sessions/${encodeURIComponent(req.params.sessionId)}`, {
            method: "DELETE",
            headers: { "X-Session-Token": token },
        });
        sessionTokens.delete(req.params.sessionId);
        return res.status(upstream.status).json(upstream.body);
    }
    catch (error) {
        return res.status(503).json(internalError(error));
    }
}
