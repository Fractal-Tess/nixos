hl.config({
	input = {
		kb_layout = "us,bg",
		kb_options = "grp:alt_shift_toggle",
		kb_variant = ",phonetic",
		follow_mouse = 1,
		sensitivity = 0,
		touchpad = {
			natural_scroll = false,
		},
	},
})

hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
hl.gesture({ fingers = 4, direction = "up", action = "float" })

hl.device({
	name = "epic-mouse-v1",
	sensitivity = -0.5,
})
