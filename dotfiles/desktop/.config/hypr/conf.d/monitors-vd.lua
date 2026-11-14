hl.monitor({ output = "DP-4", mode = "2560x1080@60", position = "0x0", scale = 1 })
hl.monitor({ output = "HDMI-A-2", mode = "2560x1440@144", position = "2560x0", scale = 1 })

-- Automatic fullscreen HDR switching causes blackouts and washed-out browser video.
hl.config({ render = { cm_auto_hdr = 0 } })
