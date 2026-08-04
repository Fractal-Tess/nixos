local colors = dofile(os.getenv("HOME") .. "/.config/colors/hyprcolors.lua")

hl.config({
	general = {
		gaps_in = 4,
		gaps_out = 8,
		border_size = 1,
		col = {
			active_border = {
				colors = { colors.primary, colors.secondary },
				angle = 45,
			},
			inactive_border = colors.outline_variant,
		},
		resize_on_border = false,
		allow_tearing = false,
		layout = "dwindle",
	},
	dwindle = {
		preserve_split = true,
	},
	master = {
		new_status = "master",
	},
	misc = {
		disable_hyprland_logo = true,
		on_focus_under_fullscreen = 2,
		enable_swallow = true,
		mouse_move_focuses_monitor = true,
		mouse_move_enables_dpms = true,
		force_default_wallpaper = 0,
	},
})
