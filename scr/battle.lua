local player_prototype       = require("scr.player")
local slot_machine_prototype = require("scr.slot_machine")
local ring_prototype         = require("scr.ring")
local damned_prototype       = require("scr.damned")
local MN                     = require("scr.const.message_names")
local settings               = require("scr.settings.game_settings")
local consts                 = require("scr.const.game_consts")
local proxy_loader           = require("scr.utils.proxy_loader")
local input_names            = require("scr.const.input_names")
local log                    = require("log.log")
local global_urls            = require("scr.const.global_urls")

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

local function spawn_damned()
    local damned_id = settings.damned_spawn_pool[math.random(#settings.damned_spawn_pool)]
    local damned_config = settings.damned[damned_id];
    local damned_url = factory.create(damned_config.factory_url)

    return damned_url, damned_id
end

local function load_level(self)
    proxy_loader.load(settings.levels.level_0.factory_url, {
        enable = true,
        acquire_input = true,
        on_loaded = function(url)
            --do somehting on level loaded
        end
    })
end

local function apply_symbols(self, symbols_apply_data, index, on_complete)
    if self.damned_model.is_dead then
        if on_complete then
            on_complete()
        end
        return
    end

    -- Start at the first symbol if no index is provided
    index = index or 1

    -- Base case: if we've processed all symbols, stop
    if index > #symbols_apply_data then
        if on_complete then
            on_complete()
        end
        return
    end

    local symbol = symbols_apply_data[index]
    local effect_config = settings.effects[symbol.effect_id]

    -- Apply the current symbol effect
    self.damned_model:apply_effect(symbol.effect_id, symbol.value)

    timer.delay(effect_config.duration, false, function()
        -- Pass self to maintain context if needed
        apply_symbols(self, symbols_apply_data, index + 1, on_complete)
    end)
end


handlers[STATES.PREPARE_BATTLE] = function(self)
    load_level()

    self.player_url = global_urls.player()
    self.player_model = player_prototype.new()

    self.slot_machine_url = global_urls.slot_machine()
    self.slot_machine_model = slot_machine_prototype.new(
        self.slot_machine_url,
        settings.slot_machine.default_reels_count)

    local damned_url, damned_config_id = spawn_damned()
    self.damned_url = damned_url
    self.damned_model = damned_prototype.new(damned_url, damned_config_id)

    self.rings = {}

    local test_ring = ring_prototype.new(msg.url(), settings.rings.footmen.id)
    print(test_ring:get_description())
    print(test_ring:get_dynamic_description())

    transition(STATES.SPIN, self)
end

handlers[STATES.SPIN] = function(self)
    self.slot_machine_model.on_spin_done = function(outcome)
        transition(STATES.APPLY_SYMBOLS, self, outcome)
    end

    self.slot_machine_model:spin()
end

handlers[STATES.APPLY_SYMBOLS] = function(self, outcome)
    self.damned_model.on_dead = function()
        transition(STATES.PLAYER_WON, self)
    end

    self.player_model.on_dead = function()
        transition(STATES.PLAYER_LOST, self)
    end

    apply_symbols(self, outcome, 1, function()
        if not self.damned_model.is_dead and
            not self.player_model.is_dead then
            transition(STATES.DAMNED_ATTACK, self)
        end
    end)
end

handlers[STATES.DAMNED_ATTACK] = function(self)
    self.damned_model.on_attack_done = function()
        transition(STATES.SPIN, self)
    end

    self.damned_model.on_attack_apply = function(amount)
        self.player_model:get_damage(amount)
    end

    self.damned_model.on_dead = function()
        transition(STATES.PLAYER_WON, self)
    end

    self.player_model.on_dead = function()
        transition(STATES.PLAYER_LOST, self)
    end

    self.damned_model:attack()
end

handlers[STATES.PLAYER_WON] = function(self)
    log:debug("Player WON!")
end

handlers[STATES.PLAYER_LOST] = function()
    log:debug("Player LOST!")
end

--===== PUBLIC API ==================================
--===================================================

function M.new()
    local self = setmetatable({
        url                = msg.url(),
        state              = nil,
        damned_url         = nil,
        damned_model       = nil,
        slot_machine_url   = nil,
        slot_machine_model = nil,
        player_url         = nil,
        player_model       = nil
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

    if message_id == MN.damned_attack_finished then
        self.damned_model:finish_attack()
    end

    if message_id == MN.damned_attack_apply then
        self.damned_model:apply_attack()
    end
end

function M:on_input(action_id, action)
    if action_id == input_names.STOP_REEL and action.pressed then
        self.slot_machine_model:stop_next_reel()
    end
end

return M
