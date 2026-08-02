-- Hyprland configuration entry point.
-- Each required file is evaluated in an isolated scope, so an error in one
-- module does not prevent the remaining modules from loading.

local config_home = os.getenv("HOME") .. "/.config/hypr/"

require(config_home .. "conf.d/monitors.lua")
require(config_home .. "hyprconfigs/hyprdecoration.lua")
require(config_home .. "hyprconfigs/hypranimations.lua")
require(config_home .. "hyprconfigs/hyprautostart.lua")
require(config_home .. "hyprconfigs/hyprenvironment.lua")
require(config_home .. "hyprconfigs/hyprpermissions.lua")
require(config_home .. "hyprconfigs/hyprlookandfeel.lua")
require(config_home .. "hyprconfigs/hyprinput.lua")
require(config_home .. "hyprconfigs/hyprkeybinds.lua")
require(config_home .. "hyprconfigs/hyprwindowsandworkspaces.lua")
require(config_home .. "hyprconfigs/hyprplugins.lua")
