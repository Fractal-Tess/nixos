"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.search = search;
const config_1 = require("../../config");
const fireEngine_v2_1 = require("./fireEngine-v2");
const searxng_1 = require("./searxng");
const ddgsearch_1 = require("./ddgsearch");
function requestedTypes(type) {
    return Array.isArray(type) ? type : type ? [type] : ["web"];
}
function resultCount(results) {
    return (results.web?.length ?? 0) + (results.images?.length ?? 0) + (results.news?.length ?? 0);
}
async function search({ query, logger, advanced = false, num_results = 5, tbs = undefined, filter = undefined, lang = "en", country = "us", location = undefined, proxy = undefined, sleep_interval = 0, timeout = 5000, type = undefined, enterprise = undefined, }) {
    try {
        if (config_1.config.FIRE_ENGINE_BETA_URL) {
            logger.info("Using fire engine search");
            return await (0, fireEngine_v2_1.fire_engine_search_v2)(query, {
                numResults: num_results,
                tbs,
                filter,
                lang,
                country,
                location,
                type,
                enterprise,
            });
        }
        let searxngResults = {};
        if (config_1.config.SEARXNG_ENDPOINT) {
            logger.info("Using SearXNG search");
            searxngResults = await (0, searxng_1.searxng_search)(query, {
                num_results,
                tbs,
                filter,
                lang,
                country,
                location,
                type,
            });
            const wantsWeb = requestedTypes(type).includes("web");
            if (resultCount(searxngResults) > 0 && (!wantsWeb || searxngResults.web?.length)) {
                return searxngResults;
            }
            if (!wantsWeb) return searxngResults;
        }
        if (!requestedTypes(type).includes("web")) return searxngResults;
        logger.info("Using DuckDuckGo web-search fallback");
        try {
            const ddgResults = await (0, ddgsearch_1.ddgSearch)(query, num_results, {
                tbs,
                lang,
                country,
                proxy,
                timeout: Math.min(timeout, 5000),
            });
            if (ddgResults.web?.length) return { ...searxngResults, web: ddgResults.web };
        }
        catch (error) {
            logger.warn("DuckDuckGo fallback failed; preserving SearXNG results", { error });
        }
        return searxngResults;
    }
    catch (error) {
        logger.error("Error in search function", { error });
        return {};
    }
}
//# sourceMappingURL=index.js.map
