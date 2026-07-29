"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.v2Router = void 0;
const express_1 = __importDefault(require("express"));
const multer_1 = __importDefault(require("multer"));
const config_1 = require("../config");
const types_1 = require("../types");
const mcp_action_logs_1 = require("./mcp-action-logs");
const autumn_service_1 = require("../services/autumn/autumn.service");
const express_ws_1 = __importDefault(require("express-ws"));
const search_1 = require("../controllers/v2/search");
const controller_1 = require("../controllers/v2/feedback/controller");
const search_feedback_1 = require("../controllers/v2/search-feedback");
const scrape_1 = require("../controllers/v2/scrape");
const keyless_eligibility_1 = require("../controllers/v2/keyless-eligibility");
const parse_1 = require("../controllers/v2/parse");
const parse_upload_1 = require("../controllers/v2/parse-upload");
const batch_scrape_1 = require("../controllers/v2/batch-scrape");
const crawl_1 = require("../controllers/v2/crawl");
const crawl_params_preview_1 = require("../controllers/v2/crawl-params-preview");
const crawl_status_1 = require("../controllers/v2/crawl-status");
const map_1 = require("../controllers/v2/map");
const crawl_errors_1 = require("../controllers/v2/crawl-errors");
const crawl_ongoing_1 = require("../controllers/v2/crawl-ongoing");
const scrape_status_1 = require("../controllers/v2/scrape-status");
const credit_usage_1 = require("../controllers/v2/credit-usage");
const token_usage_1 = require("../controllers/v2/token-usage");
const crawl_cancel_1 = require("../controllers/v2/crawl-cancel");
const concurrency_check_1 = require("../controllers/v2/concurrency-check");
const crawl_status_ws_1 = require("../controllers/v2/crawl-status-ws");
const extract_1 = require("../controllers/v2/extract");
const extract_status_1 = require("../controllers/v2/extract-status");
const shared_1 = require("./shared");
const queue_status_1 = require("../controllers/v2/queue-status");
const credit_usage_historical_1 = require("../controllers/v2/credit-usage-historical");
const token_usage_historical_1 = require("../controllers/v2/token-usage-historical");
const deprecations_1 = require("../lib/deprecations");
const agent_1 = require("../controllers/v2/agent");
const agent_status_1 = require("../controllers/v2/agent-status");
const agent_cancel_1 = require("../controllers/v2/agent-cancel");
const image_analyze_1 = require("../controllers/v2/image-analyze");
const browser_1 = require("../controllers/v2/browser");
const browser_replay_1 = require("../controllers/v2/browser-replay");
const activity_1 = require("../controllers/v1/activity");
const team_threat_protection_1 = require("../controllers/v2/team-threat-protection");
const support_proxy_1 = require("../controllers/v2/support-proxy");
const research_proxy_1 = require("../controllers/v2/research-proxy");
const scrape_browser_1 = require("../controllers/v2/scrape-browser");
const monitor_1 = require("../controllers/v2/monitor");
const slack_1 = require("../controllers/v2/slack");
exports.v2Router = express_1.default.Router();
(0, express_ws_1.default)((0, express_1.default)()).applyTo(exports.v2Router);
const parseUpload = (0, multer_1.default)({
    storage: multer_1.default.memoryStorage(),
    limits: {
        fileSize: 50 * 1024 * 1024, // 50 MB
    },
});
const parseUploadMiddleware = (req, res, next) => {
    const upload = parseUpload.single("file");
    upload(req, res, err => {
        if (!err) {
            return next();
        }
        if (err instanceof multer_1.default.MulterError && err.code === "LIMIT_FILE_SIZE") {
            return res.status(400).json({
                success: false,
                code: "BAD_REQUEST",
                error: "Uploaded file exceeds maximum size of 50MB.",
            });
        }
        return res.status(400).json({
            success: false,
            code: "BAD_REQUEST",
            error: err.message || "Invalid multipart form-data request.",
        });
    });
};
const parsePayloadMiddleware = (req, res, next) => {
    const contentType = req.headers["content-type"] || "";
    if (typeof contentType === "string" &&
        contentType.includes("multipart/form-data")) {
        return parseUploadMiddleware(req, res, err => {
            if (err)
                return next(err);
            return (0, parse_1.parseMultipartPayloadMiddleware)(req, res, next);
        });
    }
    if (req.body && typeof req.body === "object" && "uploadRef" in req.body) {
        return (0, parse_upload_1.parseUploadRefPayloadMiddleware)(req, res, next);
    }
    return res.status(400).json({
        success: false,
        code: "BAD_REQUEST",
        error: "Missing file upload. Send multipart/form-data with a 'file' field, or JSON with an 'uploadRef'.",
    });
};
// Add timing middleware to all v2 routes
exports.v2Router.use((0, shared_1.requestTimingMiddleware)("v2"));
// Internal: trusted-proxy (hosted MCP) keyless eligibility probe. Secret-gated
// inside the controller; no auth middleware.
exports.v2Router.get("/keyless/eligibility", (0, shared_1.wrap)(keyless_eligibility_1.keylessEligibilityController));
(0, mcp_action_logs_1.registerMcpActionLogReadRoute)(exports.v2Router, (0, shared_1.authMiddleware)(types_1.RateLimiterMode.Account));
exports.v2Router.post("/search", (0, shared_1.authMiddleware)(types_1.RateLimiterMode.Search, { allowKeyless: true }), shared_1.countryCheck, (0, shared_1.checkCreditsMiddleware)(undefined, autumn_service_1.SEARCH_CREDITS_FEATURE_ID), shared_1.blocklistMiddleware, (0, shared_1.wrap)(search_1.searchController));
exports.v2Router.post("/images/analyze", (0, shared_1.authMiddleware)(types_1.RateLimiterMode.Scrape, { allowKeyless: true }), shared_1.countryCheck, (0, shared_1.wrap)(image_analyze_1.imageAnalyzeController));
exports.v2Router.post("/images/from-page", (0, shared_1.authMiddleware)(types_1.RateLimiterMode.Scrape, { allowKeyless: true }), shared_1.countryCheck, (0, shared_1.wrap)(image_analyze_1.pageImagesController));
exports.v2Router.post("/search/:jobId/feedback", (0, shared_1.authMiddleware)(types_1.RateLimiterMode.Account), shared_1.validateJobIdParam, (0, shared_1.wrap)(search_feedback_1.searchFeedbackController));
exports.v2Router.post("/feedback", (0, shared_1.authMiddleware)(types_1.RateLimiterMode.Account), (0, shared_1.wrap)(controller_1.feedbackController));
exports.v2Router.post("/parse/upload-url", (0, shared_1.authMiddleware)(types_1.RateLimiterMode.Scrape, { allowKeyless: true }), shared_1.countryCheck, (0, shared_1.wrap)(parse_upload_1.parseUploadUrlController));
exports.v2Router.put("/parse/upload/:uploadId", parse_upload_1.parseLocalUploadStorageGuard, express_1.default.raw({ type: "*/*", limit: "50mb" }), (0, shared_1.wrap)(parse_upload_1.parseLocalUploadController));
exports.v2Router.post("/parse", (0, shared_1.authMiddleware)(types_1.RateLimiterMode.Scrape, { allowKeyless: true }), shared_1.countryCheck, (0, shared_1.checkCreditsMiddleware)(1), parsePayloadMiddleware, (0, shared_1.wrap)(parse_1.parseController));
exports.v2Router.post("/scrape", (0, shared_1.authMiddleware)(types_1.RateLimiterMode.Scrape, { allowKeyless: true }), shared_1.countryCheck, (0, shared_1.checkCreditsMiddleware)(1), shared_1.scrapeBlocklistMiddleware, (0, shared_1.wrap)(scrape_1.scrapeController));
exports.v2Router.get("/scrape/:jobId", (0, shared_1.authMiddleware)(types_1.RateLimiterMode.CrawlStatus), shared_1.validateJobIdParam, (0, shared_1.wrap)(scrape_status_1.scrapeStatusController));
exports.v2Router.post("/scrape/:jobId/interact", (0, shared_1.authMiddleware)(types_1.RateLimiterMode.BrowserExecute, { allowKeyless: true }), shared_1.validateJobIdParam, (0, shared_1.wrap)(scrape_browser_1.scrapeInteractController));
exports.v2Router.delete("/scrape/:jobId/interact", (0, shared_1.authMiddleware)(types_1.RateLimiterMode.BrowserExecute, { allowKeyless: true }), shared_1.validateJobIdParam, (0, shared_1.wrap)(scrape_browser_1.scrapeStopInteractiveBrowserController));
exports.v2Router.post("/batch/scrape", (0, shared_1.authMiddleware)(types_1.RateLimiterMode.Scrape), shared_1.countryCheck, (0, shared_1.checkCreditsMiddleware)(), shared_1.blocklistMiddleware, (0, shared_1.wrap)(batch_scrape_1.batchScrapeController));
exports.v2Router.post("/map", (0, shared_1.authMiddleware)(types_1.RateLimiterMode.Map), (0, shared_1.checkCreditsMiddleware)(1), shared_1.blocklistMiddleware, (0, shared_1.wrap)(map_1.mapController));
exports.v2Router.post("/crawl", (0, shared_1.authMiddleware)(types_1.RateLimiterMode.Crawl), shared_1.countryCheck, (0, shared_1.checkCreditsMiddleware)(), shared_1.scrapeBlocklistMiddleware, shared_1.idempotencyMiddleware, (0, shared_1.wrap)(crawl_1.crawlController));
exports.v2Router.post("/crawl/params-preview", (0, shared_1.authMiddleware)(types_1.RateLimiterMode.Crawl), (0, shared_1.checkCreditsMiddleware)(), (0, shared_1.wrap)(crawl_params_preview_1.crawlParamsPreviewController));
exports.v2Router.get("/crawl/ongoing", (0, shared_1.authMiddleware)(types_1.RateLimiterMode.CrawlStatus), (0, shared_1.wrap)(crawl_ongoing_1.ongoingCrawlsController));
exports.v2Router.get("/crawl/active", (0, shared_1.authMiddleware)(types_1.RateLimiterMode.CrawlStatus), (0, shared_1.wrap)(crawl_ongoing_1.ongoingCrawlsController));
exports.v2Router.get("/crawl/:jobId", (0, shared_1.authMiddleware)(types_1.RateLimiterMode.CrawlStatus), shared_1.validateJobIdParam, (0, shared_1.wrap)(crawl_status_1.crawlStatusController));
exports.v2Router.delete("/crawl/:jobId", (0, shared_1.authMiddleware)(types_1.RateLimiterMode.CrawlStatus), shared_1.validateJobIdParam, (0, shared_1.wrap)(crawl_cancel_1.crawlCancelController));
exports.v2Router.ws("/crawl/:jobId", ((ws, req, next) => {
    const jobId = Array.isArray(req.params.jobId)
        ? undefined
        : req.params.jobId;
    if (!(0, shared_1.isValidJobId)(jobId)) {
        ws.close(1008, "Invalid job ID");
        return;
    }
    next();
}), crawl_status_ws_1.crawlStatusWSController);
exports.v2Router.get("/batch/scrape/:jobId", (0, shared_1.authMiddleware)(types_1.RateLimiterMode.CrawlStatus), shared_1.validateJobIdParam, (0, shared_1.wrap)((req, res) => (0, crawl_status_1.crawlStatusController)(req, res, true)));
exports.v2Router.delete("/batch/scrape/:jobId", (0, shared_1.authMiddleware)(types_1.RateLimiterMode.CrawlStatus), shared_1.validateJobIdParam, (0, shared_1.wrap)(crawl_cancel_1.crawlCancelController));
exports.v2Router.get("/batch/scrape/:jobId/errors", (0, shared_1.authMiddleware)(types_1.RateLimiterMode.CrawlStatus), (0, shared_1.wrap)(crawl_errors_1.crawlErrorsController));
exports.v2Router.get("/crawl/:jobId/errors", (0, shared_1.authMiddleware)(types_1.RateLimiterMode.CrawlStatus), shared_1.validateJobIdParam, (0, shared_1.wrap)(crawl_errors_1.crawlErrorsController));
exports.v2Router.post("/extract", (0, shared_1.authMiddleware)(types_1.RateLimiterMode.Extract), (0, deprecations_1.deprecationMiddleware)("v2_extract"), shared_1.countryCheck, (0, shared_1.checkCreditsMiddleware)(20), shared_1.blocklistMiddleware, (0, shared_1.wrap)(extract_1.extractController));
exports.v2Router.get("/extract/:jobId", (0, shared_1.authMiddleware)(types_1.RateLimiterMode.ExtractStatus), (0, deprecations_1.deprecationMiddleware)("v2_extract_status"), shared_1.validateJobIdParam, (0, shared_1.wrap)(extract_status_1.extractStatusController));
exports.v2Router.post("/agent", (0, shared_1.authMiddleware)(types_1.RateLimiterMode.Extract), shared_1.countryCheck, (0, shared_1.checkCreditsMiddleware)(20), shared_1.blocklistMiddleware, (0, shared_1.wrap)(agent_1.agentController));
exports.v2Router.get("/agent/:jobId", (0, shared_1.authMiddleware)(types_1.RateLimiterMode.ExtractStatus), shared_1.validateJobIdParam, (0, shared_1.wrap)(agent_status_1.agentStatusController));
exports.v2Router.delete("/agent/:jobId", (0, shared_1.authMiddleware)(types_1.RateLimiterMode.ExtractStatus), shared_1.validateJobIdParam, (0, shared_1.wrap)(agent_cancel_1.agentCancelController));
exports.v2Router.get("/team/credit-usage", (0, shared_1.authMiddleware)(types_1.RateLimiterMode.Account), (0, shared_1.wrap)(credit_usage_1.creditUsageController));
exports.v2Router.get("/team/credit-usage/historical", (0, shared_1.authMiddleware)(types_1.RateLimiterMode.Account), (0, shared_1.wrap)(credit_usage_historical_1.creditUsageHistoricalController));
exports.v2Router.get("/team/token-usage", (0, shared_1.authMiddleware)(types_1.RateLimiterMode.Account), (0, shared_1.wrap)(token_usage_1.tokenUsageController));
exports.v2Router.get("/team/token-usage/historical", (0, shared_1.authMiddleware)(types_1.RateLimiterMode.Account), (0, shared_1.wrap)(token_usage_historical_1.tokenUsageHistoricalController));
exports.v2Router.get("/concurrency-check", (0, shared_1.authMiddleware)(types_1.RateLimiterMode.CrawlStatus), (0, shared_1.wrap)(concurrency_check_1.concurrencyCheckController));
exports.v2Router.get("/team/queue-status", (0, shared_1.authMiddleware)(types_1.RateLimiterMode.Account), (0, shared_1.wrap)(queue_status_1.queueStatusController));
exports.v2Router.get("/team/activity", (0, shared_1.authMiddleware)(types_1.RateLimiterMode.Account), (0, shared_1.wrap)(activity_1.activityController));
exports.v2Router.get("/team/threat-protection", (0, shared_1.authMiddleware)(types_1.RateLimiterMode.Account), (0, shared_1.wrap)(team_threat_protection_1.getTeamThreatProtectionController));
exports.v2Router.put("/team/threat-protection", (0, shared_1.authMiddleware)(types_1.RateLimiterMode.Account), (0, shared_1.wrap)(team_threat_protection_1.putTeamThreatProtectionController));
exports.v2Router.post("/monitor", (0, shared_1.authMiddleware)(types_1.RateLimiterMode.Crawl), shared_1.countryCheck, (0, shared_1.checkCreditsMiddleware)(1), shared_1.blocklistMiddleware, (0, shared_1.wrap)(monitor_1.createMonitorController));
exports.v2Router.get("/monitor", (0, shared_1.authMiddleware)(types_1.RateLimiterMode.CrawlStatus), (0, shared_1.wrap)(monitor_1.listMonitorsController));
// Public, unauthenticated — token in body is the credential. Registered
// before /monitor/:monitorId so "email" isn't parsed as a monitor UUID.
exports.v2Router.post("/monitor/email/confirm", (0, shared_1.wrap)(monitor_1.confirmMonitorEmailController));
exports.v2Router.post("/monitor/email/unsubscribe", (0, shared_1.wrap)(monitor_1.unsubscribeMonitorEmailController));
exports.v2Router.get("/monitor/:monitorId", (0, shared_1.authMiddleware)(types_1.RateLimiterMode.CrawlStatus), (0, shared_1.wrap)(monitor_1.getMonitorController));
exports.v2Router.patch("/monitor/:monitorId", (0, shared_1.authMiddleware)(types_1.RateLimiterMode.Crawl), shared_1.countryCheck, (0, shared_1.checkCreditsMiddleware)(1), shared_1.blocklistMiddleware, (0, shared_1.wrap)(monitor_1.updateMonitorController));
exports.v2Router.delete("/monitor/:monitorId", (0, shared_1.authMiddleware)(types_1.RateLimiterMode.CrawlStatus), (0, shared_1.wrap)(monitor_1.deleteMonitorController));
exports.v2Router.post("/monitor/:monitorId/run", (0, shared_1.authMiddleware)(types_1.RateLimiterMode.Crawl), shared_1.countryCheck, (0, shared_1.checkCreditsMiddleware)(1), shared_1.blocklistMiddleware, (0, shared_1.wrap)(monitor_1.runMonitorController));
exports.v2Router.get("/monitor/:monitorId/checks", (0, shared_1.authMiddleware)(types_1.RateLimiterMode.CrawlStatus), (0, shared_1.wrap)(monitor_1.listMonitorChecksController));
exports.v2Router.get("/monitor/:monitorId/checks/:checkId", (0, shared_1.authMiddleware)(types_1.RateLimiterMode.CrawlStatus), (0, shared_1.wrap)(monitor_1.getMonitorCheckController));
// Slack integration ("Add to Slack" + /monitor slash command).
// Public endpoints (OAuth callback, slash command, events) authenticate via the
// OAuth state nonce / Slack request signature rather than a Firecrawl API key.
exports.v2Router.post("/slack/oauth/start", (0, shared_1.authMiddleware)(types_1.RateLimiterMode.CrawlStatus), (0, shared_1.wrap)(slack_1.slackOAuthStartController));
exports.v2Router.get("/slack/oauth/callback", (0, shared_1.wrap)(slack_1.slackOAuthCallbackController));
exports.v2Router.get("/slack/status", (0, shared_1.authMiddleware)(types_1.RateLimiterMode.CrawlStatus), (0, shared_1.wrap)(slack_1.slackStatusController));
exports.v2Router.get("/slack/channels", (0, shared_1.authMiddleware)(types_1.RateLimiterMode.CrawlStatus), (0, shared_1.wrap)(slack_1.slackChannelsController));
exports.v2Router.delete("/slack/installation", (0, shared_1.authMiddleware)(types_1.RateLimiterMode.CrawlStatus), (0, shared_1.wrap)(slack_1.slackDisconnectController));
exports.v2Router.post("/slack/commands", (0, shared_1.wrap)(slack_1.slackCommandsController));
exports.v2Router.post("/slack/events", (0, shared_1.wrap)(slack_1.slackEventsController));
exports.v2Router.post(["/browser", "/interact"], (0, shared_1.authMiddleware)(types_1.RateLimiterMode.Browser), shared_1.countryCheck, (0, shared_1.checkCreditsMiddleware)(2), (0, shared_1.wrap)(browser_1.browserCreateController));
exports.v2Router.get(["/browser", "/interact"], (0, shared_1.authMiddleware)(types_1.RateLimiterMode.BrowserExecute), (0, shared_1.wrap)(browser_1.browserListController));
exports.v2Router.post(["/browser/:sessionId/execute", "/interact/:sessionId/execute"], (0, shared_1.authMiddleware)(types_1.RateLimiterMode.BrowserExecute), (0, shared_1.wrap)(browser_1.browserExecuteController));
exports.v2Router.get(["/browser/:sessionId/replay", "/interact/:sessionId/replay"], (0, shared_1.authMiddleware)(types_1.RateLimiterMode.BrowserReplay), (0, shared_1.wrap)(browser_replay_1.browserReplayController));
exports.v2Router.get(["/browser/:sessionId/replay/:pageId", "/interact/:sessionId/replay/:pageId"], (0, shared_1.authMiddleware)(types_1.RateLimiterMode.BrowserReplay), (0, shared_1.wrap)(browser_replay_1.browserReplayPageController));
exports.v2Router.delete(["/browser/:sessionId", "/interact/:sessionId"], (0, shared_1.authMiddleware)(types_1.RateLimiterMode.BrowserExecute), (0, shared_1.wrap)(browser_1.browserDeleteController));
exports.v2Router.post("/browser/webhook/destroyed", (0, shared_1.wrap)(browser_1.browserWebhookDestroyedController));
// Support agent proxy — forwards to the support-agent service.
exports.v2Router.post("/support/ask", (0, shared_1.authMiddleware)(types_1.RateLimiterMode.SupportAsk), (0, shared_1.wrap)(support_proxy_1.supportProxyController));
exports.v2Router.post("/support/docs-search", (0, shared_1.authMiddleware)(types_1.RateLimiterMode.SupportDocsSearch), (0, shared_1.wrap)(support_proxy_1.supportProxyController));
if (config_1.config.RESEARCH_PROXY_URL) {
    exports.v2Router.use("/search/research", (0, shared_1.authMiddleware)(types_1.RateLimiterMode.Research, { allowKeyless: true }), (0, research_proxy_1.createResearchRouter)());
    exports.v2Router.use("/research", (0, shared_1.authMiddleware)(types_1.RateLimiterMode.Research), (0, research_proxy_1.createResearchRouter)({ legacy: true }));
}
//# sourceMappingURL=v2.js.map