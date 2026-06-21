local player = require("scr.player")
local slot_machine = require("scr.slot_machine")
local MN = require("scr.const.message_names")
local settings = require("scr.settings.game_settings")
local consts =require("scr.const.game_consts")

local M = {}

local STATES = {
    SPIN = "spin",
    APPLY_SYMBOLS = "apply_symbols",
    DAMNED_ATTACK = "damned_attack",
    CHECK_END = "check_end",
    PLAYER_WON = "player_won",
    PLAYER_LOST = "player_lost"
}

M.state = nil
M.url = nil

local handlers = {}

local function is_player_dead()
    return player.health <= 0
end

function M.transition(new_state, ...)
    M.state = new_state
    handlers[new_state](...)
end

handlers[STATES.SPIN] = function ()
    M.slot_machine.on_spin_done = function (outcome)
        
    end

    
end

function M.start()
    M.url = msg.url()
end

return M
