---@module 'hl'

-- https://wiki.hyprland.org/Configuring/

-- You can split this configuration into multiple files.
-- Create them separately under ~/.config/hypr/ and pull them in with Lua's
-- own require(), e.g.:
--   require("myColors")   -- loads ~/.config/hypr/myColors.lua

--###############

--## MONITORS ###

--###############

-- See https://wiki.hyprland.org/Configuring/Monitors/

hl.monitor({
    output = "eDP-1",
    mode = "1920x1080@60",
    position = "0x0",
    scale = 1,
})

hl.monitor({
    output = "HDMI-A-1",
    mode = "1920x1080@165",
    position = "auto",
    scale = 1,
    mirror = "eDP-1",
})

--################

--## AUTOSTART ###

--################

-- See https://wiki.hypr.land/Configuring/Basics/Autostart/

hl.on("hyprland.start", function()
    -- hyprpm plugins (hyprcapture) aren't loaded on login unless reloaded here
    hl.exec_cmd("hyprpm reload -n")
    -- `;` not `&&`: on a fresh install wal has no palette to restore yet, and the shell must start anyway
    hl.exec_cmd("sh -c 'wal -R; sleep 0.2; qs -p ~/.config/quickshell'")
    hl.exec_cmd("kitty", { workspace = "1 silent" })
    hl.exec_cmd("copyq")
end)

--############################

--## ENVIRONMENT VARIABLES ###

--############################

-- See https://wiki.hyprland.org/Configuring/Environment-variables/

hl.env("XCURSOR_SIZE", 24)

hl.env("HYPRCURSOR_SIZE", 24)

hl.env("HYPRCURSOR_THEME", "Bibata-Modern-Classic")

hl.env("HYPRSHOT_DIR", os.getenv("HOME") .. "/Pictures/screenshots")

--####################

--## LOOK AND FEEL ###

--####################

-- Refer to https://wiki.hyprland.org/Configuring/Variables/

-- https://wiki.hyprland.org/Configuring/Variables/#general

hl.config({
    general = {
        gaps_in = 1,
        gaps_out = 2,
        border_size = 0,
        -- Set to true enable resizing windows by clicking and dragging on borders and gaps
        resize_on_border = false,
        -- Please see https://wiki.hyprland.org/Configuring/Tearing/ before you turn this on
        allow_tearing = false,
        layout = "dwindle",
    },
})

-- https://wiki.hyprland.org/Configuring/Variables/#decoration

hl.config({
    decoration = {
        rounding = 8,
        active_opacity = 1.0,
        inactive_opacity = .85,
        shadow = {
            enabled = false,
        },
        -- https://wiki.hyprland.org/Configuring/Variables/#blur
        blur = {
            enabled = true,
            size = 5,
            passes = 1,
            vibrancy = 0.1696,
        },
    },
})

hl.config({
    animations = {
        enabled = true,
    },
})
hl.curve("easeOutQuint", {
    type = "bezier",
    points = { { 0.23, 1 }, { 0.32, 1 } },
})
hl.curve("linear", {
    type = "bezier",
    points = { { 0, 0 }, { 1, 1 } },
})
hl.curve("almostLinear", {
    type = "bezier",
    points = { { 0.5, 0.5 }, { 0.75, 1.0 } },
})
hl.curve("quick", {
    type = "bezier",
    points = { { 0.15, 0 }, { 0.1, 1 } },
})
hl.animation({ leaf = "global", enabled = true, speed = 10, bezier = "default" })
hl.animation({ leaf = "border", enabled = true, speed = 5.39, bezier = "easeOutQuint" })
hl.animation({ leaf = "windows", enabled = true, speed = 1.79, bezier = "easeOutQuint" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 4.1, bezier = "easeOutQuint", style = "popin 80%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 1.49, bezier = "linear", style = "popin 80%" })
hl.animation({ leaf = "fadeIn", enabled = true, speed = 1.43, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut", enabled = true, speed = 1.46, bezier = "almostLinear" })
hl.animation({ leaf = "fade", enabled = false, speed = 3.03, bezier = "quick" })
hl.animation({ leaf = "layers", enabled = true, speed = 3.81, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn", enabled = true, speed = 4, bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 1.5, bezier = "linear", style = "fade" })
hl.animation({ leaf = "fadeLayersIn", enabled = true, speed = 1.79, bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1.39, bezier = "almostLinear" })
hl.animation({ leaf = "workspaces", enabled = false, speed = 1.94, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesIn", enabled = false, speed = 1.21, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesOut", enabled = false, speed = 1.94, bezier = "almostLinear", style = "fade" })

-- Ref https://wiki.hyprland.org/Configuring/Workspace-Rules/

-- See https://wiki.hyprland.org/Configuring/Dwindle-Layout/ for more

hl.config({
    dwindle = {
        preserve_split = true,
    },
})

hl.config({
    misc = {
        background_color = "0x000000",
        force_default_wallpaper = 0,
        -- Set to 0 or 1 to disable the anime mascot wallpapers
        disable_hyprland_logo = true,
        -- If true disables the random hyprland logo / anime girl background. :(
    },
})

--############

--## INPUT ###

--############

-- https://wiki.hyprland.org/Configuring/Variables/#input

hl.config({
    input = {
        kb_layout = "hu",
        follow_mouse = 1,
        sensitivity = 0.5,
        touchpad = {
            natural_scroll = true,
        },
        accel_profile = "adaptive",
    },
})

-- https://wiki.hyprland.org/Configuring/Variables/#gestures

hl.config({
    gestures = {
        workspace_swipe_distance = 100,
    },
})

hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace", scale = 0.5 })
hl.gesture({ fingers = 3, direction = "vertical", scale = 1.5, action = "fullscreen" })

--##################

--## KEYBINDINGS ###

--##################

-- See https://wiki.hyprland.org/Configuring/Keywords/

local mainMod = "SUPER"

-- Sets "Windows" key as main modifier

hl.bind(mainMod .. " + " .. "RETURN", hl.dsp.exec_cmd("kitty"))
hl.bind(mainMod .. " + " .. "Q", hl.dsp.window.close())
hl.bind(mainMod .. " + " .. "M", hl.dsp.exit())
hl.bind(mainMod .. " + " .. "E", hl.dsp.exec_cmd("dolphin"))
hl.bind(mainMod .. " + " .. "C", hl.dsp.window.float())
hl.bind(mainMod .. " + " .. "P", hl.dsp.window.pseudo())

-- dwindle

hl.bind(mainMod .. " + " .. "J", hl.dsp.layout("togglesplit"))

-- Move focus with mainMod + arrow keys

hl.bind(mainMod .. " + " .. "left", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + " .. "right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + " .. "up", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + " .. "down", hl.dsp.focus({ direction = "down" }))
hl.bind(mainMod .. " + " .. "SHIFT" .. " + " .. "left", hl.dsp.window.move({ direction = "left" }))
hl.bind(mainMod .. " + " .. "SHIFT" .. " + " .. "right", hl.dsp.window.move({ direction = "right" }))
hl.bind(mainMod .. " + " .. "SHIFT" .. " + " .. "up", hl.dsp.window.move({ direction = "up" }))
hl.bind(mainMod .. " + " .. "SHIFT" .. " + " .. "down", hl.dsp.window.move({ direction = "down" }))

-- Switch workspaces with mainMod + [0-9]

hl.bind(mainMod .. " + " .. 1, hl.dsp.focus({ workspace = 1 }))
hl.bind(mainMod .. " + " .. 2, hl.dsp.focus({ workspace = 2 }))
hl.bind(mainMod .. " + " .. 3, hl.dsp.focus({ workspace = 3 }))
hl.bind(mainMod .. " + " .. 4, hl.dsp.focus({ workspace = 4 }))
hl.bind(mainMod .. " + " .. 5, hl.dsp.focus({ workspace = 5 }))
hl.bind(mainMod .. " + " .. 6, hl.dsp.focus({ workspace = 6 }))
hl.bind(mainMod .. " + " .. 7, hl.dsp.focus({ workspace = 7 }))
hl.bind(mainMod .. " + " .. 8, hl.dsp.focus({ workspace = 8 }))
hl.bind(mainMod .. " + " .. 9, hl.dsp.focus({ workspace = 9 }))
hl.bind(mainMod .. " + " .. 0, hl.dsp.focus({ workspace = 10 }))

-- Move active window to a workspace with mainMod + SHIFT + [0-9]

hl.bind(mainMod .. " + " .. "SHIFT" .. " + " .. 1, hl.dsp.window.move({ workspace = 1 }))
hl.bind(mainMod .. " + " .. "SHIFT" .. " + " .. 2, hl.dsp.window.move({ workspace = 2 }))
hl.bind(mainMod .. " + " .. "SHIFT" .. " + " .. 3, hl.dsp.window.move({ workspace = 3 }))
hl.bind(mainMod .. " + " .. "SHIFT" .. " + " .. 4, hl.dsp.window.move({ workspace = 4 }))
hl.bind(mainMod .. " + " .. "SHIFT" .. " + " .. 5, hl.dsp.window.move({ workspace = 5 }))
hl.bind(mainMod .. " + " .. "SHIFT" .. " + " .. 6, hl.dsp.window.move({ workspace = 6 }))
hl.bind(mainMod .. " + " .. "SHIFT" .. " + " .. 7, hl.dsp.window.move({ workspace = 7 }))
hl.bind(mainMod .. " + " .. "SHIFT" .. " + " .. 8, hl.dsp.window.move({ workspace = 8 }))
hl.bind(mainMod .. " + " .. "SHIFT" .. " + " .. 9, hl.dsp.window.move({ workspace = 9 }))
hl.bind(mainMod .. " + " .. "SHIFT" .. " + " .. 0, hl.dsp.window.move({ workspace = 10 }))

-- Scroll through existing workspaces with mainMod + scroll

hl.bind(mainMod .. " + " .. "mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + " .. "mouse_up", hl.dsp.focus({ workspace = "e-1" }))

-- Move/resize windows with mainMod + LMB/RMB and dragging
-- TODO(verify): I could not confirm hl.dsp.window.drag()/window.resize() or the
-- { mouse = true } bind option against the official dispatcher docs (this maps
-- from the old bindm + movewindow/resizewindow combo). Test these binds after
-- reload; if they don't work, check the Binds and Dispatchers pages on
-- wiki.hypr.land for the current mouse-drag equivalent.

hl.bind(mainMod .. " + " .. "mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + " .. "mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Laptop multimedia keys for volume and LCD brightness

hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), { locked = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { locked = true })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl s 10%+"), { locked = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl s 10%-"), { locked = true })

-- Requires playerctl

hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })

-- CUSTOM

hl.bind("SHIFT + ALT + C", hl.dsp.exec_cmd("hyprpicker"))
hl.bind(mainMod .. " + " .. "F", hl.dsp.window.fullscreen())
hl.bind(mainMod .. " + " .. "L", hl.dsp.exec_cmd("hyprlock"))
hl.bind(mainMod .. " + " .. "V", hl.dsp.exec_cmd("copyq toggle"))
hl.bind(mainMod .. " + " .. "SHIFT" .. " + " .. "S", hl.dsp.exec_cmd("hyprshot -m region"))
hl.bind("Print", hl.dsp.exec_cmd("hyprcapture-ui"))   
-- HyprCapture is optional, and nil until hyprpm loads it
if hl.plugin.hyprcapture then
    hl.bind("SUPER + CTRL + s", hl.plugin.hyprcapture.record_stop)
end

--#############################

--## WINDOWS AND WORKSPACES ###

--#############################

-- See https://wiki.hyprland.org/Configuring/Window-Rules/ for more
-- See https://wiki.hyprland.org/Configuring/Workspace-Rules/ for workspace rules
-- Ignore maximize requests from apps. You'll probably like this.

hl.window_rule({
    name  = "maximize-ignore",
    match = {
        class = ".*",
    },
    suppress_event = "maximize",
})

-- Fix some dragging issues with XWayland

hl.window_rule({
    name  = "drag-fix",
    match = {
        class = "^$",
        title = "^$",
        xwayland = true,
        float = true,
        fullscreen = false,
        pin = false,
    },
    no_focus = true,
})

-- CUSTOM

hl.window_rule({
    name  = "copyq-popup",
    match = {
        class = "^(copyq|com\\.github\\.hluk\\.copyq)$",
    },
    float = true,
    size = { 300, 400 },
    center = true,
})

-- Quickshell animates its own windows, a compositor fade on top cuts them short
hl.layer_rule({
    match = {
        namespace = "^(quickshell)$",
    },
    no_anim = true,
})

-- Personal overrides (keyboard layout, monitors...) in ~/.config/hypr/user.lua, git-ignored so updates never conflict
local user = io.open(os.getenv("HOME") .. "/.config/hypr/user.lua")
if user then
    user:close()
    require("user")
end
