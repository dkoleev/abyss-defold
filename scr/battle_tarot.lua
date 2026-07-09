local settings       = require("scr.settings.game_settings")
local proxy_loader   = require("scr.utils.proxy_loader")
local table_utils    = require("scr.utils.table_utils")
local deck_prototype = require("scr.deck")

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

local function discard_card(self, card)
    table_utils.remove_value_from_array(self.spread, card)
    self.deck:discard_card(card)
end

local function play_card(self, card)
    table_utils.remove_value_from_array(self.spread, card)
    self.selected_cards[#self.selected_cards+1] = card
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
    load_level()

    self.deck:build(settings.tarot)

    transition(self, STATES.FILL_SPREAD)
end

handlers[STATES.FILL_SPREAD] = function(self)
    local spread_size = settings.battle.spread_default_size
    for i = 1, spread_size do
        self.spread[#self.spread + 1] = self.deck:draw_card()
    end

    -- pprint(self.deck)
    -- pprint(self.spread)

    -- discard_card(self, self.spread[1])

    -- pprint(self.deck)
    -- pprint(self.spread)

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
        spread         = {},                   -- current cards for choice
        selected_cards = {}
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
