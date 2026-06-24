local M = {}

function M.battle()
    return msg.url("/root#battle")
end

function M.slot_machine()
    return msg.url("/slot_machine#slot_machine")
end

function M.player()
    return msg.url("/player#player")
end

function M.damned_spawn_point()
    return msg.url("/damned_spawn_point")
end

function M.symbols_root()
    return msg.url("/symbols_root")
end

return M
