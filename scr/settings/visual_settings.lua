local M = {}

M.slots = {
    scroll_speed = 200,
    symbol_size = 32
}

M.card = {
    width                = 64,
    width_half           = 32,
    height               = 96,
    height_half          = 48,
    flip_duration        = 0.3,
    base_scale           = vmath.vector3(1),
    hover_scale          = vmath.vector3(1.08),
    hover_lift           = 10, -- pixels up
    hover_lift_duration  = 0.12,
    hover_scale_duration = 0.12,
    hover_z_position     = 0.1,
    front_sprite_url     = "#sprite",
    back_sprite_url      = "#back_sprite"
}

return M
