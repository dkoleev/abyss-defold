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
    holding_scale        = vmath.vector3(1.16),
    holding_threshold    = 0.20,
    hover_scale          = vmath.vector3(1.08),
    hover_lift           = 0, -- pixels up
    hover_lift_duration  = 0.0,
    hover_scale_duration = 0.1,
    hover_position_z     = 0.1,
    select_scale          = vmath.vector3(1.16),
    select_lift           = 10, -- pixels up
    select_lift_duration  = 0.1,
    select_scale_duration = 0.1,
    select_position_z     = 0.1,
    
    front_sprite_url     = "#sprite",
    back_sprite_url      = "#back_sprite"
}

return M
