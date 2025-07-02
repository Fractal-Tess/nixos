-- compress.yazi.lua: Improved Yazi archive plugin
-- Always prompts for archive name and extension

local is_windows = ya.target_family() == "windows"
local default_extension = "zip"

local function is_valid_filename(name)
    name = name:match("^%s*(.-)%s*$")
    if name == "" then return false end
    if is_windows then
        if name:find('[<>:"/\\|%?%*]') then return false end
    else
        if name:find("/") or name:find("%z") then return false end
    end
    return true
end

local function notify_error(message, urgency)
    ya.notify({
        title = "Archive",
        content = message,
        level = urgency,
        timeout = 5
    })
end

local function is_command_available(cmd)
    local stat_cmd
    if is_windows then
        stat_cmd = string.format("where %s > nul 2>&1", cmd)
    else
        stat_cmd = string.format("command -v %s >/dev/null 2>&1", cmd)
    end
    local cmd_exists = os.execute(stat_cmd)
    return cmd_exists and true or false
end

local function find_command_name(cmd_list)
    for _, cmd in ipairs(cmd_list) do
        if is_command_available(cmd) then
            return cmd
        end
    end
    return cmd_list[1]
end

local function combine_url(path, file)
    path, file = Url(path), Url(file)
    return tostring(path:join(file))
end

local selected_or_hovered = ya.sync(function()
    local tab, paths, names, path_fnames = cx.active, {}, {}, {}
    for _, u in pairs(tab.selected) do
        paths[#paths + 1] = tostring(u.parent)
        names[#names + 1] = tostring(u.name)
    end
    if #paths == 0 and tab.current.hovered then
        paths[1] = tostring(tab.current.hovered.url.parent)
        names[1] = tostring(tab.current.hovered.name)
    end
    for idx, name in ipairs(names) do
        if not path_fnames[paths[idx]] then
            path_fnames[paths[idx]] = {}
        end
        table.insert(path_fnames[paths[idx]], name)
    end
    return path_fnames, names, tostring(tab.current.cwd)
end)

local archive_commands = {
    ["%.zip$"] = {
        {command = "zip", args = {"-r"}},
        {command = {"7z", "7zz", "7za"}, args = {"a", "-tzip"}},
        {command = {"tar", "bsdtar"}, args = {"-caf"}},
    },
    ["%.7z$"] = {
        {command = {"7z", "7zz", "7za"}, args = {"a"}},
    },
    ["%.rar$"] = {
        {command = "rar", args = {"a"}},
    },
    ["%.tar.gz$"] = {
        {command = {"tar", "bsdtar"}, args = {"-czf"}},
    },
    ["%.tar.xz$"] = {
        {command = {"tar", "bsdtar"}, args = {"-cJf"}},
    },
    ["%.tar.bz2$"] = {
        {command = {"tar", "bsdtar"}, args = {"-cjf"}},
    },
    ["%.tar.zst$"] = {
        {command = {"tar", "bsdtar"}, args = {"--zstd", "-cf"}},
    },
    ["%.tar.lz4$"] = {
        {command = {"tar", "bsdtar"}, args = {"--lz4", "-cf"}},
    },
    ["%.tar.lha$"] = {
        {command = {"tar", "bsdtar"}, args = {"-caf"}},
    },
    ["%.tar$"] = {
        {command = {"tar", "bsdtar"}, args = {"-cf"}},
    },
}

return {
    entry = function(_, job)
        local path_fnames, fnames, output_dir = selected_or_hovered()
        local default_name = (#fnames == 1 and fnames[1]) or Url(output_dir).name
        local output_name, event = ya.input({
            title = "Create archive (add extension):",
            value = default_name .. "." .. default_extension,
            position = {"top-center", y = 3, w = 40}
        })
        if event ~= 1 then return end
        if not output_name:match("%.[%w%.]+$") then
            output_name = output_name .. "." .. default_extension
        end
        if not is_valid_filename(output_name) then
            notify_error("Invalid archive filename", "error")
            return
        end
        local archive_cmd, archive_args
        local matched_pattern = false
        for pattern, cmd_list in pairs(archive_commands) do
            if output_name:match(pattern) then
                matched_pattern = true
                for _, cmd in ipairs(cmd_list) do
                    local find_command = type(cmd.command) == "table" and find_command_name(cmd.command) or cmd.command
                    if is_command_available(find_command) then
                        archive_cmd = find_command
                        archive_args = cmd.args
                        break
                    end
                end
                if archive_cmd then break end
            end
        end
        if not matched_pattern then
            notify_error("Unsupported file extension", "error")
            return
        end
        if not archive_cmd then
            notify_error("No suitable archiver found for this format", "error")
            return
        end
        local temp_dir_name = ".tmp_compress"
        local temp_dir = combine_url(output_dir, temp_dir_name)
        temp_dir, _ = tostring(fs.unique_name(Url(temp_dir)))
        local temp_dir_status, temp_dir_err = fs.create("dir_all", Url(temp_dir))
        if not temp_dir_status then
            notify_error("Failed to create temp directory: " .. tostring(temp_dir_err), "error")
            return
        end
        local temp_output_url = combine_url(temp_dir, output_name)
        -- Helper for file-based debug logging
        local function log_debug(msg)
            local f = io.open("/tmp/yazi-compress-debug.log", "a")
            if f then
                f:write(os.date("[%Y-%m-%d %H:%M:%S] ") .. msg .. "\n")
                f:close()
            end
        end
        log_debug("Running: " .. archive_cmd .. " " .. table.concat(archive_args, " "))
        log_debug("Output: " .. temp_output_url)
        for filepath, filenames in pairs(path_fnames) do
            log_debug("CWD: " .. filepath .. ", Files: " .. table.concat(filenames, ", "))
            local archive_status, archive_err =
                Command(archive_cmd):arg(archive_args):arg(temp_output_url):arg(filenames):cwd(filepath):spawn():wait()
            if not archive_status or not archive_status.success then
                log_debug(string.format("Failed to create archive %s with '%s', error: %s", output_name, archive_cmd, tostring(archive_err)))
                fs.remove("dir_all", Url(temp_dir))
                job:done()
                return
            else
                log_debug("Archive command succeeded for " .. temp_output_url)
            end
        end
        -- Check if temp output file exists
        local f = io.open(temp_output_url, "rb")
        if not f then
            log_debug("Archive file was not created at temp location!")
            fs.remove("dir_all", Url(temp_dir))
            job:done()
            return
        else
            f:close()
            log_debug("Archive file exists at temp location.")
        end
        local final_output_url, temp_url_processed = combine_url(output_dir, output_name), combine_url(temp_dir, output_name)
        final_output_url, _ = tostring(fs.unique_name(Url(final_output_url)))
        log_debug("Moving archive from " .. temp_url_processed .. " to " .. final_output_url)
        local move_status, move_err = os.rename(temp_url_processed, final_output_url)
        if not move_status then
            log_debug(string.format("Failed to move %s to %s, error: %s", temp_url_processed, final_output_url, tostring(move_err)))
            fs.remove("dir_all", Url(temp_dir))
            job:done()
            return
        else
            log_debug("Moved archive to " .. final_output_url)
        end
        fs.remove("dir_all", Url(temp_dir))
        log_debug("Cleanup done. Job finished.")
        job:done()
    end
} 