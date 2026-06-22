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

return M
