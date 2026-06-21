local settings = require("scr.settings.game_settings")

local M = {}

M.health = nil

function M.init()
    M.health = settings.player.health       
end

return M