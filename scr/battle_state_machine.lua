local player       = require("scr.player")
local slot_machine = require("scr.slot_machine")
local MN           = require("scr.const.message_names")
local settings     = require("scr.settings.game_settings")
local consts       = require("scr.const.game_consts")
local proxy_loader = require("scr.utils.proxy_loader")

local M            = {}
M.__index          = M

local handlers     = {}

local STATES       = {
    PREPARE_BATTLE = "prepare_battle",
    SPIN           = "spin",
    APPLY_SYMBOLS  = "apply_symbols",
    DAMNED_ATTACK  = "damned_attack",
    CHECK_END      = "check_end",
    PLAYER_WON     = "player_won",
    PLAYER_LOST    = "player_lost"
}

local function transition(new_state, ...)
    M.state = new_state
    handlers[new_state](...)
end

local function is_player_dead()
    return player.health <= 0
end

local function load_level()
    proxy_loader.load(settings.levels.level_0.factory_url, {
        enable = true,
        acquire_input = true,
        on_loaded = function(url)
            M.spawn_damned()
        end
    })
end

local function spawn_damned()
    local damned_id = settings.damned_spawn_pool[math.random(#settings.damned_spawn_pool)]
    local damned_config = settings.damned[damned_id];

    local damned_url = factory.create(damned_config.factory_url, nil, nil, {
        config_id = damned_id
    })

    return damned_url
end


handlers[STATES.PREPARE_BATTLE] = function(self)
    load_level()
    self.damned_url = spawn_damned()
    transition(STATES.SPIN)
end

handlers[STATES.SPIN] = function()

end

--===== PUBLIC API ==================================
--===================================================

function M.new()
    local self = setmetatable({
        url              = msg.url(),
        state            = nil,
        damned_url       = nil,
        slot_machine_url = nil,
        player_url       = nil
    }, M)

    return self
end

function M:start()
    transition(STATES.PREPARE_BATTLE, self)
end

function M:on_message(message_id, message, sender)
    proxy_loader.on_message(message_id, message, sender)
end

return M
