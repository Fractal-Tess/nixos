local get_state = ya.sync(function()
	local h = cx.active.current.hovered
	if not h then return nil end

	local cwd  = tostring(cx.active.current.cwd)
	local name = tostring(h.url.name)

	local targets = {}
	if #cx.active.selected == 0 then
		targets = { name }
	else
		for _, url in pairs(cx.active.selected) do
			targets[#targets + 1] = tostring(url.name)
		end
	end

	return { cwd = cwd, name = name, targets = targets }
end)

return {
	entry = function()
		local s = get_state()
		if not s then return end

		local parts = {}
		for _, f in ipairs(s.targets) do
			parts[#parts + 1] = ya.quote(f)
		end

		local cmd = "zip -r " .. ya.quote(s.name .. ".zip") .. " " .. table.concat(parts, " ")

		ya.emit("shell", { cmd, block = true, confirm = true, cwd = s.cwd })
	end,
}
