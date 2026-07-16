local settings       = require("scr.settings.game_settings")
local proxy_loader   = require("scr.utils.proxy_loader")
local table_utils    = require("scr.utils.table_utils")
local deck_prototype = require("scr.deck")
local global_urls    = require("scr.const.global_urls")
local spread_utils   = require("scr.utils.spread_utils")
local MN             = require("scr.const.message_names")

local M              = {}
M.__index            = M

local handlers       = {}

local STATES         = {
    PREPARE_BATTLE = "prepare_battle",
    FILL_SPREAD    = "fill_spread",
    SELECT_CARDS   = "select_cards",
    APPLY_CARDS    = "apply_cards",
    APPLY_RINGS    = "apply_rings",
    DAMNED_ATTACK  = "damned_attack",
    CHECK_END      = "check_end",
    PLAYER_WON     = "player_won",
    PLAYER_LOST    = "player_lost"
}

local function load_level()
    proxy_loader.load(settings.levels.level_0.factory_url, {
        enable = true,
        acquire_input = true,
        on_loaded = function(url)
            print("Loaded")
            --do somehting on level loaded
        end
    })
end

--Call this whenever cards are added or removed from spread
local function refresh_spread(self)
    local tween_duration = 0.25
    local count = #self.spread
    local layout = spread_utils.compute(count)
    local spawn_point = go.get_position(global_urls.spread_center_point())

    for i, card in ipairs(self.spread) do
        local offset = layout[i]

        local target_pos = vmath.vector3(
            spawn_point.x + offset.x,
            spawn_point.y + offset.y,
            spawn_point.z - i * 0.01) -- late cards on top

        local target_rot = vmath.quat_rotation_z(math.rad(offset.rotation))

        go.animate(self.card_urls[i], "position", go.PLAYBACK_ONCE_FORWARD,
            target_pos, go.EASING_OUTQUAD, tween_duration)
        go.animate(self.card_urls[i], "rotation", go.PLAYBACK_ONCE_FORWARD,
            target_rot, go.EASING_OUTQUAD, tween_duration)
        msg.post(self.card_urls[i], MN.change_rotation, { rotation = offset.rotation })
    end
end

local function create_deck_view(self)
    local pos = go.get_world_position(global_urls.deck_spawn_point())
    local deck_config = settings.decks.deck_0

    self.deck_url = factory.create(deck_config.factory_url, pos)
end

local function discard_card(self, card)
    table_utils.remove_value_from_array(self.spread, card)
    self.deck:discard_card(card)
end

local function play_card(self, card)
    table_utils.remove_value_from_array(self.spread, card)
    self.selected_cards[#self.selected_cards + 1] = card
end

local function apply_cards(self)
    for _, card in self.select_cards do
        --TODO: apply card
    end
end

local function transition(self, new_state, ...)
    self.state = new_state
    handlers[new_state](self, ...)
end

handlers[STATES.PREPARE_BATTLE] = function(self)
    self.deck:build(settings.tarot)

    load_level()
    create_deck_view(self)

    transition(self, STATES.FILL_SPREAD)
end

handlers[STATES.FILL_SPREAD] = function(self)
    local spread_size = settings.battle.spread_default_size
    for i = 1, spread_size do
        local card = self.deck:draw_card()
        self.spread[#self.spread + 1] = card
        local pos = go.get_position(global_urls.spread_center_point())
        -- local props = { initial_animation = hash(card.sprite) }
        local props = { card_id = hash(card.id) }
        local card_url = factory.create(settings.battle.tarot_card_factory_url, pos, nil, props)
        --TODO: remove and hole card go in spread instead
        self.card_urls[#self.card_urls + 1] = card_url

        refresh_spread(self)
    end

    transition(self, STATES.SELECT_CARDS)
end

handlers[STATES.SELECT_CARDS] = function(self)

end

--===== PUBLIC API ==================================
--===================================================

function M.new()
    local self = setmetatable({
        url            = msg.url(),
        state          = nil,
        damned_url     = nil,
        damned_model   = nil,
        player_url     = nil,
        player_model   = nil,
        rings          = {},
        deck           = deck_prototype.new(), -- shuffled tarot cards
        deck_url       = nil,
        spread         = {},                   -- current cards for choice
        selected_cards = {},
        card_urls      = {}
    }, M)

    return self
end

function M:start()
    transition(self, STATES.PREPARE_BATTLE)
end

function M:on_message(message_id, message, sender)
    proxy_loader.on_message(message_id, message, sender)
end

return M
