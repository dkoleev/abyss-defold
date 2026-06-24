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
local rings_runner           = require("scr.ring_runner")
local table_utils            = require("scr.utils.table_utils")

local M                      = {}
M.__index                    = M

local handlers               = {}

local STATES                 = {
    PREPARE_BATTLE = "prepare_battle",
    SPIN           = "spin",
    APPLY_RINGS    = "apply_rings",
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

local function spawn_damned(self)
    local damned_id = settings.damned_spawn_pool[math.random(#settings.damned_spawn_pool)]
    local damned_config = settings.damned[damned_id];
    local damned_url = factory.create(damned_config.factory_url)

    self.damned_url = damned_url
    self.damned_model = damned_prototype.new(damned_url, damned_id)
end

local function add_ring(self, ring_id)
    local root_pos = go.get_position("/rings_root")
    local current_rings_count = #self.rings
    local pos = vmath.vector3(root_pos.x + 30 * current_rings_count, root_pos.y, root_pos.z)

    local config = settings.rings[ring_id]
    local url = factory.create(config.factory_url, pos)

    table.insert(self.rings, ring_prototype.new(url, ring_id))
end

-- example: remove_ring(self, settings.rings.footmen.id)
local function remove_ring(self, ring_id)
    local ring, ring_index = table_utils.find(self.rings, function(ring, i) 
        return ring.config_id == ring_id
    end)

    table.remove(self.rings, ring_index)
    ring:delete()
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

local function apply_symbols(self, symbols_apply_data, index, context, on_complete)
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

    local symbol_context = {
        symbol = symbol,
        bd     = 0,
    }

    rings_runner.fire_event(self.rings, "on_symbol_resolved", symbol_context)


    -- Apply the current symbol effect
    -- self.damned_model:apply_effect(symbol.effect_id, symbol.value)

    context.dmg = context.dmg + symbol.value + symbol_context.bd

    -- TODO: apply symbol value effect
    timer.delay(settings.battle.durations.add_symbol_value_to_result, false, function()
        -- Pass self to maintain context if needed
        apply_symbols(self, symbols_apply_data, index + 1, context, on_complete)
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

    spawn_damned(self)

    -- Add start rings
    -- TODO: setup through the shop
    add_ring(self, settings.rings.footmen.id)
    add_ring(self, settings.rings.watcher.id)

    transition(STATES.SPIN, self)
end

handlers[STATES.SPIN] = function(self)
    self.slot_machine_model.on_spin_done = function(outcome)
        transition(STATES.APPLY_RINGS, self, outcome)
    end

    self.slot_machine_model:spin()
end

handlers[STATES.APPLY_RINGS] = function(self, outcome)
    local context = {
        outcome = outcome,
        dmg = 0,
        dmg_mult = 1
    }

    rings_runner.fire_event(self.rings, "on_spin_end", context)

    transition(STATES.APPLY_SYMBOLS, self, outcome, context)
end

handlers[STATES.APPLY_SYMBOLS] = function(self, outcome, context)
    self.damned_model.on_dead = function()
        self.damned_model = nil
        transition(STATES.PLAYER_WON, self)
    end

    self.player_model.on_dead = function()
        transition(STATES.PLAYER_LOST, self)
    end

    apply_symbols(self, outcome, 1, context, function()
        local final_damage = context.dmg * context.dmg_mult
        log:debug("final damage applied to damned: " .. final_damage)
        self.damned_model:apply_effect(consts.effects.p_dmg, final_damage)

        timer.delay(settings.battle.durations.apply_damage_to_damned, false, function()
            if not self.damned_model.is_dead and
                not self.player_model.is_dead then
                transition(STATES.DAMNED_ATTACK, self)
            end
        end)
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
        player_model       = nil,
        rings              = {}
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
