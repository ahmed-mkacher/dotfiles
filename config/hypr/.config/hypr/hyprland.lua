local home = os.getenv("HOME")
local hypr = home .. "/.config/hypr"
package.path = package.path .. ";" .. home .. "/.config/caelestia/?.lua"

-- Create a file if it doesn't exist, optionally with initial content
local function maybe_create(file, content)
	local f = io.open(file)

	if f then
		f:close()
		return
	end

	f = io.open(file, "w")
	if f then
		if content then
			f:write(content)
		end
		f:close()
	end
end

-- Copy src to dst, but only if dst doesn't already exist
local function maybe_copy(src, dst)
	local out = io.open(dst)
	if out then
		out:close()
		return
	end

	local input = io.open(src, "r")
	if not input then
		return
	end

	out = io.open(dst, "w")
	if out then
		out:write(input:read("*a"))
		out:close()
	end
	input:close()
end

-- Maybe set current colours to defaults
maybe_copy(hypr .. "/scheme/default.lua", hypr .. "/scheme/current.lua")

-- Monitors are auto-detected by default. If you need explicit placement
-- (e.g. multi-monitor layout, specific resolution/refresh), add hl.monitor()
-- blocks here. Run `hyprctl monitors` to list your outputs.
-- hl.monitor({ output = "DP-1", mode = "preferred", position = "0x0", scale = 1 })

--[====[ NVIDIA on Wayland — what you need and why ]====
-- If you have an NVIDIA GPU on Wayland / Hyprland, the following are
-- commonly required. They are commented out by default so the config
-- works out of the box on Intel/AMD systems.
--
-- Especially important for laptops with hybrid graphics (NVIDIA dGPU +
-- Intel iGPU) driving external monitors: the monitors are physically
-- wired to the dGPU. Without AQ_DRM_DEVICES, Hyprland may composite on
-- the iGPU and then copy every frame to the dGPU for scanout, causing
-- visible lag and stutter on external displays.
--
-- The AQ_DRM_DEVICES line below forces the dGPU as primary so
-- compositing and scanout happen on the same GPU. It uses stable
-- symlinks because AQ_DRM_DEVICES cannot parse by-path colons.
-- Create the symlinks first (see install.sh) or replace the paths.
--
-- Uncomment the block below if you have a similar setup:
--]====]
-- hl.env("LIBVA_DRIVER_NAME", "nvidia")
-- hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
-- hl.env("GBM_BACKEND", "nvidia-drm")
-- hl.env("AQ_DRM_DEVICES", home .. "/.config/hypr/nvidia-card:" .. home .. "/.config/hypr/intel-card")
--
-- hl.config({ cursor = { no_hardware_cursors = true } })  -- fixes cursor stutter on external monitors

-- Configs
require("hyprland.env")
require("hyprland.general")
require("hyprland.input")
require("hyprland.misc")
require("hyprland.animations")
require("hyprland.decoration")
require("hyprland.group")
require("hyprland.execs")
require("hyprland.rules")
require("hyprland.gestures")
require("hyprland.keybinds")

-- User configs — machine-specific (not tracked in dotfiles)
maybe_create(
	home .. "/.config/caelestia/hypr-user.lua",
	[[
-- Machine-specific Hyprland overrides — edit for THIS machine.
-- Not tracked by dotfiles; each machine is different.
-- Run `hyprctl monitors` to list your outputs.
--
-- hl.monitor({ output = "", mode = "preferred", position = "0x0", scale = 1 })
--
-- For NVIDIA hybrid-graphics (dGPU driving external monitors):
--   hl.env("LIBVA_DRIVER_NAME", "nvidia")
--   hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
--   hl.env("GBM_BACKEND", "nvidia-drm")
--   hl.env("AQ_DRM_DEVICES", home .. "/.config/hypr/nvidia-card:" .. home .. "/.config/hypr/intel-card")
--   hl.config({ cursor = { no_hardware_cursors = true } })
--]]
)
require("hypr-user")
