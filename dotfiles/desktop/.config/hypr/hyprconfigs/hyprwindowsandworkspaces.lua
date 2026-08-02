hl.window_rule({ match = { title = [[^(UnityEngine.*)]] }, min_size = { 200, 400 }, float = true })
hl.window_rule({ match = { title = [[^(UnityEditor.*)]] }, min_size = { 200, 400 }, float = true })
hl.window_rule({ match = { class = [[^(dev.warp.Warp)$]] }, float = true })
hl.window_rule({ match = { title = [[^(File Operation Progress)$]] }, float = true })
hl.window_rule({ match = { class = [[^(discord)$]] }, workspace = "1" })
hl.window_rule({ match = { class = [[^(dev.zed.Zed)$]] }, workspace = "2" })
hl.window_rule({ match = { class = [[^(cursor)$]] }, workspace = "2" })
hl.window_rule({ match = { class = [[^(Vivaldi-stable)$]] }, workspace = "3" })
hl.window_rule({ match = { class = [[^(com\.gabm\.satty)$]] }, float = true })
hl.window_rule({
	match = { class = [[^(clip-sync-switcher)$]] },
	float = true,
	center = true,
	size = { 720, 480 },
})
hl.window_rule({ match = { class = ".*" }, suppress_event = "maximize" })

hl.window_rule({
	name = "pavucontrol-float",
	match = { class = [[^(org.pulseaudio.pavucontrol)$]] },
	float = true,
	size = { 879, 879 },
})

hl.window_rule({
	name = "blueman-float",
	match = { class = [[^(blueman-manager)$]] },
	float = true,
	size = { 879, 879 },
})

hl.layer_rule({ match = { namespace = "swaync-control-center" }, animation = "slide" })
hl.layer_rule({ match = { namespace = "hyprpicker" }, animation = "fade" })
