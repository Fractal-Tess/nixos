hl.config({
	ecosystem = {
		no_update_news = true,
		no_donation_nag = true,
	},
})

hl.permission({
	binary = "/usr/(lib|libexec|lib64)/xdg-desktop-portal-hyprland",
	type = "screencopy",
	mode = "allow",
})

hl.permission({
	binary = "/usr/(bin|local/bin)/hyprpm",
	type = "plugin",
	mode = "allow",
})
