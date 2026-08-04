local programs = dofile(os.getenv("HOME") .. "/.config/hypr/hyprconfigs/hyprprograms.lua")
local mod = programs.main_mod

hl.bind(mod .. " + P", hl.dsp.exec_cmd(programs.menu))
hl.bind(mod .. " + SHIFT + Q", hl.dsp.window.close())
hl.bind(mod .. " + Return", hl.dsp.exec_cmd(programs.terminal))
hl.bind(mod .. " + F", hl.dsp.window.float())
hl.bind(mod .. " + SHIFT + F", hl.dsp.window.fullscreen({ mode = "fullscreen" }))
hl.bind(mod .. " + W", hl.dsp.exec_cmd("~/nixos/scripts/display/workspace swap"))
hl.bind(mod .. " + SHIFT + H", hl.dsp.window.move({ direction = "l" }))
hl.bind(mod .. " + SHIFT + L", hl.dsp.window.move({ direction = "r" }))
hl.bind(mod .. " + SHIFT + K", hl.dsp.window.move({ direction = "u" }))
hl.bind(mod .. " + SHIFT + J", hl.dsp.window.move({ direction = "d" }))
hl.bind(mod .. " + SHIFT + W", hl.dsp.window.move({ monitor = "+1" }))
hl.bind(mod .. " + ALT + H", hl.dsp.window.resize({ x = -60, y = 0, relative = true }))
hl.bind(mod .. " + ALT + L", hl.dsp.window.resize({ x = 60, y = 0, relative = true }))
hl.bind(mod .. " + LEFT", hl.dsp.window.move({ x = -60, y = 0, relative = true }))
hl.bind(mod .. " + UP", hl.dsp.window.move({ x = 0, y = -60, relative = true }))
hl.bind(mod .. " + DOWN", hl.dsp.window.move({ x = 0, y = 60, relative = true }))
hl.bind(mod .. " + RIGHT", hl.dsp.window.move({ x = 60, y = 0, relative = true }))
hl.bind(mod .. " + A", hl.dsp.exec_cmd(programs.browser))
hl.bind(mod .. " + C", hl.dsp.exec_cmd("zeditor"))
hl.bind(mod .. " + D", hl.dsp.exec_cmd("discord"))
hl.bind(mod .. " + E", hl.dsp.exec_cmd(programs.file_manager))
hl.bind(mod .. " + V", hl.dsp.exec_cmd(programs.editor))
hl.bind(mod .. " + Y", hl.dsp.exec_cmd(programs.browser .. " https://youtube.com"))
hl.bind(mod .. " + G", hl.dsp.exec_cmd(programs.browser .. " https://github.com"))
hl.bind(mod .. " + H", hl.dsp.exec_cmd("~/nixos/scripts/session/clipboard"))
hl.bind(mod .. " + SHIFT + X", hl.dsp.exec_cmd("~/nixos/scripts/session/screenshot"))
hl.bind(mod .. " + Z", hl.dsp.exec_cmd("hyprpicker"))
hl.bind(mod .. " + B", hl.dsp.exec_cmd("~/.config/RofiScripts/WallpaperChanger/WallMenu.sh"))
hl.bind(mod .. " + SHIFT + B", hl.dsp.exec_cmd("waypaper"))
hl.bind(mod .. " + L", hl.dsp.exec_cmd("hyprlock"))
hl.bind(mod .. " + SHIFT + L", hl.dsp.exec_cmd("uwsm stop"))

for workspace = 1, 6 do
	hl.bind(mod .. " + " .. workspace, hl.dsp.focus({ workspace = workspace }))
	hl.bind(mod .. " + SHIFT + " .. workspace, hl.dsp.window.move({ workspace = workspace, follow = true }))
end

hl.bind(mod .. " + S", hl.dsp.workspace.toggle_special("magic"))
hl.bind(mod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic", follow = true }))
hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })
hl.bind(mod .. " + ESCAPE", hl.dsp.exec_cmd("~/nixos/scripts/session/powermenu"))
hl.bind(mod .. " + SHIFT + R", hl.dsp.exec_cmd("pkill waybar && waybar &"))
hl.bind(mod .. " + SHIFT + T", hl.dsp.exec_cmd("killall -SIGUSR1 waybar"))
hl.bind(mod .. " + ALT + T", hl.dsp.exec_cmd("killall -SIGUSR1 waybar"))

hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("pactl set-sink-volume @DEFAULT_SINK@ +5%"))
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("pactl set-sink-volume @DEFAULT_SINK@ -5%"))
hl.bind("code:123", hl.dsp.exec_cmd("pactl set-sink-volume @DEFAULT_SINK@ +1%"), { release = true })
hl.bind("code:122", hl.dsp.exec_cmd("pactl set-sink-volume @DEFAULT_SINK@ -1%"), { release = true })
hl.bind("mouse:276", hl.dsp.exec_cmd("pactl set-sink-volume @DEFAULT_SINK@ +1%"), { release = true })
hl.bind("mouse:277", hl.dsp.exec_cmd("pactl set-sink-volume @DEFAULT_SINK@ -1%"), { release = true })
hl.bind(
	"XF86AudioMute",
	hl.dsp.exec_cmd(
		[[pactl set-sink-mute @DEFAULT_SINK@ toggle && notify-send "Audio" "$(pactl get-sink-mute @DEFAULT_SINK@ | grep -q 'yes' && echo '🔇 Muted' || echo '🔊 Unmuted')" -h string:x-canonical-private-synchronous:audio-status]]
	)
)
hl.bind(
	"XF86AudioMicMute",
	hl.dsp.exec_cmd(
		[[pactl set-source-mute @DEFAULT_SOURCE@ toggle && notify-send "Microphone" "$(pactl get-source-mute @DEFAULT_SOURCE@ | grep -q 'yes' && echo '🎤 Muted' || echo '🎤 Unmuted')" -h string:x-canonical-private-synchronous:mic-status]]
	)
)
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"))
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"))
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"))
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"))
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"))
hl.bind("XF86AudioStop", hl.dsp.exec_cmd("playerctl stop"))
hl.bind("XF86Calculator", hl.dsp.exec_cmd("~/.config/RofiScripts/RofiCalc/Calc.sh"))
hl.bind("XF86HomePage", hl.dsp.exec_cmd(programs.browser))
hl.bind("Print", hl.dsp.exec_cmd("~/nixos/scripts/session/screenshot"))
hl.bind("XF86ScreenSaver", hl.dsp.exec_cmd("loginctl lock-session"))
hl.bind("XF86Sleep", hl.dsp.exec_cmd("systemctl suspend"))
hl.bind(
	mod .. " + M",
	hl.dsp.exec_cmd(
		[[hyprctl dispatch dpms off && notify-send "Monitors" "Turned off" -h string:x-canonical-private-synchronous:monitor-status]]
	)
)
hl.bind(mod .. " + SHIFT + M", hl.dsp.exec_cmd("~/nixos/scripts/display/screen monitor-on"))
hl.bind(mod .. " + CTRL + M", hl.dsp.exec_cmd("~/nixos/scripts/display/screen monitor-off"))
hl.bind(mod .. " + CTRL + A", hl.dsp.exec_cmd("~/nixos/scripts/audio/sink menu"))
hl.bind(mod .. " + CTRL + B", hl.dsp.exec_cmd("~/nixos/scripts/display/screen menu"))
hl.bind("XF86Search", hl.dsp.exec_cmd(programs.browser .. " https://www.google.com"))
hl.bind("switch:on:Lid Switch", hl.dsp.exec_cmd("~/nixos/scripts/display/screen lid-close"), { locked = true })
hl.bind("switch:off:Lid Switch", hl.dsp.exec_cmd("~/nixos/scripts/display/screen lid-open"), { locked = true })
