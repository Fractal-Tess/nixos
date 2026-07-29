"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.searxng_search = searxng_search;
const axios_1 = __importDefault(require("axios"));
const config_1 = require("../../config");
const logger_1 = require("../../lib/logger");
function requestedTypes(type) {
    const values = Array.isArray(type) ? type : type ? [type] : ["web"];
    return [...new Set(values.filter(value => ["web", "images", "news"].includes(value)))];
}
function resolution(value) {
    if (Array.isArray(value) && value.length >= 2) {
        return { width: Number(value[0]) || undefined, height: Number(value[1]) || undefined };
    }
    if (typeof value === "string") {
        const match = /(\d+)\s*[x×]\s*(\d+)/i.exec(value);
        if (match) return { width: Number(match[1]), height: Number(match[2]) };
    }
    if (value && typeof value === "object") {
        return { width: Number(value.width) || undefined, height: Number(value.height) || undefined };
    }
    return {};
}
function validHttpUrl(value) {
    if (typeof value !== "string") return undefined;
    try {
        const url = new URL(value);
        return url.protocol === "http:" || url.protocol === "https:" ? url.href : undefined;
    }
    catch {
        return undefined;
    }
}
function transformResult(result, type, position) {
    if (type === "images") {
        const imageUrl = validHttpUrl(result.img_src) ?? validHttpUrl(result.thumbnail_src);
        if (!imageUrl) return undefined;
        const size = resolution(result.resolution);
        return {
            title: result.title || undefined,
            imageUrl,
            imageWidth: size.width,
            imageHeight: size.height,
            url: validHttpUrl(result.url),
            position,
        };
    }
    if (type === "news") {
        const url = validHttpUrl(result.url);
        if (!url) return undefined;
        return {
            title: result.title || undefined,
            url,
            snippet: result.content || undefined,
            date: result.publishedDate || result.pubdate || undefined,
            imageUrl: validHttpUrl(result.img_src) ?? validHttpUrl(result.thumbnail_src),
            position,
        };
    }
    const url = validHttpUrl(result.url);
    if (!url) return undefined;
    return {
        url,
        title: result.title || "",
        description: result.content || "",
        position,
    };
}
async function searxng_search(q, options) {
    const requestedResults = Math.max(options.num_results, 0);
    if (requestedResults === 0) return {};
    const startPage = options.page ?? 1;
    const cleanedUrl = config_1.config.SEARXNG_ENDPOINT.endsWith("/")
        ? config_1.config.SEARXNG_ENDPOINT.slice(0, -1)
        : config_1.config.SEARXNG_ENDPOINT;
    const finalUrl = cleanedUrl + "/search";
    const output = {};
    try {
        await Promise.all(requestedTypes(options.type).map(async type => {
            const category = type === "web" ? (config_1.config.SEARXNG_CATEGORIES || "general") : type;
            const collected = [];
            const seen = new Set();
            for (let pageOffset = 0; pageOffset < Math.max(1, Math.ceil(requestedResults / 10)); pageOffset += 1) {
                const response = await axios_1.default.get(finalUrl, {
                    headers: { "Content-Type": "application/json" },
                    params: {
                        q,
                        language: options.lang,
                        engines: config_1.config.SEARXNG_ENGINES ?? "",
                        categories: category,
                        pageno: startPage + pageOffset,
                        format: "json",
                    },
                    timeout: 15000,
                });
                const results = Array.isArray(response.data?.results) ? response.data.results : [];
                for (const candidate of results) {
                    const transformed = transformResult(candidate, type, collected.length + 1);
                    const key = transformed && (type === "images" ? transformed.imageUrl : transformed.url);
                    if (!transformed || !key || seen.has(key)) continue;
                    seen.add(key);
                    collected.push(transformed);
                    if (collected.length >= requestedResults) break;
                }
                if (collected.length >= requestedResults || results.length === 0) break;
            }
            if (collected.length > 0) output[type] = collected;
        }));
        return output;
    }
    catch (error) {
        logger_1.logger.error("There was an error searching SearXNG", { error });
        return output;
    }
}
//# sourceMappingURL=searxng.js.map
