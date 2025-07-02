-- compress.yazi.lua: Improved Yazi archive plugin
-- Always prompts for archive name and extension

return {
    entry = function(_, job)
        -- Always log at the very start
        local function log_debug(msg)
            local ok, f = pcall(io.open, "/tmp/yazi-compress-debug.log", "a")
            if ok and f then
                f:write(os.date("[%Y-%m-%d %H:%M:%S] ") .. msg .. "\n")
                f:close()
            end
        end
        log_debug("Plugin entry called")

        local is_windows = ya.target_family() == "windows"
        log_debug("is_windows: " .. tostring(is_windows))
        local default_extension = "zip"
        log_debug("default_extension: " .. default_extension)

        local function is_valid_filename(name)
            name = name:match("^%s*(.-)%s*$")
            if name == "" then log_debug("Filename is empty"); return false end
            if is_windows then
                if name:find('[<>:"/\\|%?%*]') then log_debug("Filename has forbidden Windows chars"); return false end
            else
                if name:find("/") or name:find("%z") then log_debug("Filename has forbidden Unix chars"); return false end
            end
            return true
        end

        local function notify_error(message, urgency)
            log_debug("notify_error: " .. message .. " (" .. urgency .. ")")
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
            log_debug("is_command_available(" .. cmd .. "): " .. tostring(cmd_exists))
            return cmd_exists and true or false
        end

        local function find_command_name(cmd_list)
            for _, cmd in ipairs(cmd_list) do
                if is_command_available(cmd) then
                    log_debug("find_command_name: found " .. cmd)
                    return cmd
                end
            end
            log_debug("find_command_name: fallback to " .. cmd_list[1])
            return cmd_list[1]
        end

        local function combine_url(path, file)
            path, file = Url(path), Url(file)
            return tostring(path:join(file))
        end

        local function selected_or_hovered()
            return ya.sync(function()
                log_debug("selected_or_hovered called")
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
                log_debug("selected_or_hovered: paths=" .. table.concat(paths, ",") .. ", names=" .. table.concat(names, ","))
                return path_fnames, names, tostring(tab.current.cwd)
            end)()
        end

        log_debug("Calling selected_or_hovered...")
        local path_fnames, fnames, output_dir = selected_or_hovered()
        log_debug("selected_or_hovered returned. output_dir=" .. tostring(output_dir))
        local default_name = (#fnames == 1 and fnames[1]) or Url(output_dir).name
        log_debug("default_name: " .. tostring(default_name))

        log_debug("Prompting for output file name...")
        local output_name, event = ya.input({
            title = "Create archive (add extension):",
            value = default_name .. "." .. default_extension,
            position = {"top-center", y = 3, w = 40}
        })
        log_debug("Prompt result: output_name=" .. tostring(output_name) .. ", event=" .. tostring(event))
        if event ~= 1 then
            log_debug("User cancelled filename prompt.")
            job:done()
            return
        end

        if not output_name:match("%.[%w%.]+$") then
            output_name = output_name .. "." .. default_extension
            log_debug("Appended default extension. output_name=" .. output_name)
        end
        if not is_valid_filename(output_name) then
            notify_error("Invalid archive filename", "error")
            log_debug("Invalid archive filename: " .. output_name)
            job:done()
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
                        log_debug("Selected archiver: " .. archive_cmd .. ", args: " .. table.concat(archive_args, ", "))
                        break
                    end
                end
                if archive_cmd then break end
            end
        end
        if not matched_pattern then
            notify_error("Unsupported file extension", "error")
            log_debug("Unsupported file extension: " .. output_name)
            job:done()
            return
        end
        if not archive_cmd then
            notify_error("No suitable archiver found for this format", "error")
            log_debug("No suitable archiver found for: " .. output_name)
            job:done()
            return
        end
        local temp_dir_name = ".tmp_compress"
        local temp_dir = combine_url(output_dir, temp_dir_name)
        temp_dir, _ = tostring(fs.unique_name(Url(temp_dir)))
        log_debug("Creating temp dir: " .. temp_dir)
        local temp_dir_status, temp_dir_err = fs.create("dir_all", Url(temp_dir))
        log_debug("Temp dir status: " .. tostring(temp_dir_status) .. ", err: " .. tostring(temp_dir_err))
        if not temp_dir_status then
            notify_error("Failed to create temp directory: " .. tostring(temp_dir_err), "error")
            job:done()
            return
        end
        local temp_output_url = combine_url(temp_dir, output_name)
        log_debug("Temp output url: " .. temp_output_url)
        for filepath, filenames in pairs(path_fnames) do
            log_debug("CWD: " .. filepath .. ", Files: " .. table.concat(filenames, ", "))
            log_debug("About to spawn command at " .. os.date("%Y-%m-%d %H:%M:%S"))
            local archive_status, archive_err
            local ok, err = pcall(function()
                local cmd = Command(archive_cmd)
                for _, arg in ipairs(archive_args) do
                    cmd:arg(arg)
                end
                cmd:arg(temp_output_url)
                for _, fname in ipairs(filenames) do
                    cmd:arg(fname)
                end
                cmd:cwd(filepath)
                archive_status, archive_err = cmd:spawn():wait()
            end)
            log_debug("Spawn returned at " .. os.date("%Y-%m-%d %H:%M:%S"))
            if not ok then
                log_debug("pcall error: " .. tostring(err))
            end
            log_debug("archive_status: " .. tostring(archive_status) .. ", archive_err: " .. tostring(archive_err))
            if not archive_status or (type(archive_status) == "table" and not archive_status.success) then
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
        log_debug("Move status: " .. tostring(move_status) .. ", err: " .. tostring(move_err))
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