-- Reapply the hardware lid state after startup and every config reload.
-- Monitor rules can otherwise re-enable eDP while the lid remains closed.
hl.exec_cmd("sleep 0.2 && ~/nixos/scripts/display/screen lid-sync")

hl.on("hyprland.start", function()
	hl.exec_cmd("gnome-keyring-daemon --start --components=secrets")
	hl.exec_cmd("waypaper --backend awww --restore")
	hl.exec_cmd("hyprctl setcursor Bibata-Modern-Ice 24")
	hl.exec_cmd("blueman-applet")
	hl.exec_cmd("nm-applet")
	hl.exec_cmd("swaync")
end)
