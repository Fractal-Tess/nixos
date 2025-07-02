-- compress.yazi.lua: Improved Yazi archive plugin
-- Always prompts for archive name and extension

return {
    entry = function(_, job)
        local function log_debug(msg)
            local ok, f = pcall(io.open, "/tmp/yazi-compress-debug.log", "a")
            if ok and f then
                f:write(os.date("[%Y-%m-%d %H:%M:%S] ") .. msg .. "\n")
                f:close()
            end
        end
        log_debug("Plugin entry called")

        local output_name, event = ya.input({
            title = "Test prompt",
            value = "test.zip",
            position = {"top-center", y = 3, w = 40}
        })
        log_debug("Prompt result: output_name=" .. tostring(output_name) .. ", event=" .. tostring(event))
        job:done()
    end
} 