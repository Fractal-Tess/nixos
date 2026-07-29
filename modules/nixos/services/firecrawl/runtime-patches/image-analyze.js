"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.imageAnalyzeController = imageAnalyzeController;
exports.pageImagesController = pageImagesController;
const config_1 = require("../../config");
async function proxy(req, res, path) {
    if (!config_1.config.EXTRACT_V3_BETA_URL || !config_1.config.AGENT_INTEROP_SECRET) {
        return res.status(503).json({ success: false, error: "Local image-analysis service is not configured" });
    }
    try {
        const response = await fetch(`${config_1.config.EXTRACT_V3_BETA_URL}${path}`, {
            method: "POST",
            headers: {
                "Content-Type": "application/json",
                Authorization: `Bearer ${config_1.config.AGENT_INTEROP_SECRET}`,
            },
            body: JSON.stringify(req.body),
        });
        const text = await response.text();
        let body;
        try {
            body = JSON.parse(text);
        }
        catch {
            body = { success: false, error: text || "Image service returned an invalid response" };
        }
        return res.status(response.status).json(body);
    }
    catch (error) {
        return res.status(503).json({
            success: false,
            error: `Local image service is unavailable: ${error instanceof Error ? error.message : String(error)}`,
        });
    }
}
async function imageAnalyzeController(req, res) {
    return proxy(req, res, "/v1/images/analyze");
}
async function pageImagesController(req, res) {
    return proxy(req, res, "/v1/images/from-page");
}
