-- Hyprland configuration entry point.
-- Load each configuration file by path in the required order.

local config_home = os.getenv("HOME") .. "/.config/hypr/"

local config_files = {
	"conf.d/monitors.lua",
	"hyprconfigs/hyprdecoration.lua",
	"hyprconfigs/hypranimations.lua",
	"hyprconfigs/hyprautostart.lua",
	"hyprconfigs/hyprenvironment.lua",
	"hyprconfigs/hyprpermissions.lua",
	"hyprconfigs/hyprlookandfeel.lua",
	"hyprconfigs/hyprinput.lua",
	"hyprconfigs/hyprkeybinds.lua",
	"hyprconfigs/hyprwindowsandworkspaces.lua",
	"hyprconfigs/hyprplugins.lua",
}

for _, config_file in ipairs(config_files) do
	dofile(config_home .. config_file)
end
