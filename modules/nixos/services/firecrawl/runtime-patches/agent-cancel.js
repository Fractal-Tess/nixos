"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.agentCancelController = agentCancelController;
const config_1 = require("../../config");
async function agentCancelController(req, res) {
    if (!config_1.config.EXTRACT_V3_BETA_URL || !config_1.config.AGENT_INTEROP_SECRET) {
        return res.status(503).json({ success: false, error: "Local agent service is not configured" });
    }
    try {
        const response = await fetch(`${config_1.config.EXTRACT_V3_BETA_URL}/internal/extracts/${encodeURIComponent(req.params.jobId)}`, {
            method: "DELETE",
            headers: { Authorization: `Bearer ${config_1.config.AGENT_INTEROP_SECRET}` },
        });
        const text = await response.text();
        let body;
        try {
            body = JSON.parse(text);
        }
        catch {
            body = { success: false, error: text || "Local agent returned an invalid response" };
        }
        return res.status(response.status).json(body);
    }
    catch (error) {
        return res.status(503).json({
            success: false,
            error: `Local agent service is unavailable: ${error instanceof Error ? error.message : String(error)}`,
        });
    }
}
//# sourceMappingURL=agent-cancel.js.map
