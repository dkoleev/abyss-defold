local player                 = require("scr.player")
local slot_machine_prototype = require("scr.slot_machine")
local MN                     = require("scr.const.message_names")
local settings               = require("scr.settings.game_settings")
local consts                 = require("scr.const.game_consts")
local proxy_loader           = require("scr.utils.proxy_loader")
local input_names            = require("scr.const.input_names")

local M                      = {}
M.__index                    = M

local handlers               = {}

local STATES                 = {
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

local function apply_symbols(self, symbols_apply_data, index)
    -- Start at the first symbol if no index is provided
    index = index or 1

    -- Base case: if we've processed all symbols, stop
    if index > #symbols_apply_data then
        return
    end

    local symbol = symbols_apply_data[index]

    -- Apply the current symbol effect
    msg.post(self.damned_url, MN.apply_effect, {
        effect = symbol.effect_id,
        value = symbol.value
    })

    local effect_config = settings.effects[symbol.effect_id]

    timer.delay(effect_config.duration, false, function()
        -- Pass self to maintain context if needed
        apply_symbols(self, symbols_apply_data, index + 1)
    end)
end


handlers[STATES.PREPARE_BATTLE] = function(self)
    load_level()

    self.slot_machine_url = msg.url("/slot_machine#slot_machine")
    self.slot_machine_model = slot_machine_prototype.new(
        self.slot_machine_url,
        settings.slot_machine.default_reels_count)

    self.damned_url = spawn_damned()
    transition(STATES.SPIN, self)
end

handlers[STATES.SPIN] = function(self)
    self.slot_machine_model.on_spin_done = function(outcome)
        transition(STATES.APPLY_SYMBOLS, self, outcome)
    end

    self.slot_machine_model:spin()
end

handlers[STATES.APPLY_SYMBOLS] = function(self, outcome)
    apply_symbols(self, outcome)
end

--===== PUBLIC API ==================================
--===================================================

function M.new()
    local self = setmetatable({
        url                = msg.url(),
        state              = nil,
        damned_url         = nil,
        slot_machine_url   = nil,
        slot_machine_model = nil,
        player_url         = nil
    }, M)

    return self
end

function M:start()
    transition(STATES.PREPARE_BATTLE, self)
end

function M:on_message(message_id, message, sender)
    proxy_loader.on_message(message_id, message, sender)

    if message_id == MN.reel_stopped then
        self.slot_machine_model:on_reel_stopped(message)
    end
end

function M:on_input(action_id, action)
    -- any tap / Space stops the next unlocked reel in order
    if action_id == input_names.STOP_REEL and action.pressed then
        self.slot_machine_model:stop_next_reel()
        -- if self.model.spinning and self.current_stop <= #self.reel_urls then
        -- 	msg.post(self.reel_urls[self.current_stop], MN.stop_reel, {
        -- 		reel_index = self.current_stop,
        -- 		reply_to   = msg.url(),
        -- 	})
        -- 	self.current_stop = self.current_stop + 1
        -- end
    end
end

return M
