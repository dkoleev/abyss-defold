local MN = require("scr.const.message_names")
local battle = require("scr.battle")
local settings = require("scr.settings.game_settings")

local M = {}

local REEL_COUNT = 3

local function apply_symbols(self, symbols_apply_data, index)
	-- Start at the first symbol if no index is provided
	index = index or 1

	-- Base case: if we've processed all symbols, stop
	if index > #symbols_apply_data then
		return
	end

	local symbol = symbols_apply_data[index]

	-- Apply the current symbol effect
	msg.post(battle.current_damned, MN.apply_effect, {
		effect = symbol.effect_id,
		value = symbol.value
	})

	local effect_config = settings.effects[symbol.effect_id]

	timer.delay(effect_config.duration, false, function()
		-- Pass self to maintain context if needed
		apply_symbols(self, symbols_apply_data, index + 1)
	end)
end

function M.new(reel_urls)
    local sm = {
        reels        = reel_urls, -- array of reel GO urls
        results      = {},        -- filled as reels stop
        stopped      = 0,
        spinning     = false,
        on_spin_done = nil, -- callback(results)
    }

    return sm
end

function M.spin(self)
    self.results = {}
    self.stopped = 0
    self.spinning = true
    for _, url in ipairs(self.reels) do
        msg.post(url, MN.start_spin)
    end
end

-- Call from parent script's on_message
function M.on_reel_stopped(self, message)
    self.results[message.reel_index] = message.symbol
    self.stopped = self.stopped + 1

    if self.stopped == #self.reels then
        self.spinning = false
        local outcome = M.evaluate(self.results)
        if self.on_spin_done then
            battle.apply_slot_machine_symbols(outcome)
            -- apply_symbols(self, outcome)
            self.on_spin_done(outcome)
        end
    end
end

function M.evaluate(results)
    local counts = {}
    for _, sym in ipairs(results) do
        counts[sym.id] = (counts[sym.id] or 0) + 1
    end

    local symbol_apply_data = {}
    for reel_index, symbol in ipairs(results) do
        local is_triple = counts[symbol.id] == REEL_COUNT;
        local multiplier = is_triple and 2 or 1 -- triple = bonus
        table.insert(symbol_apply_data, {
            reel_index = reel_index,
            type       = symbol.type,
            value      = symbol.value * multiplier,
            effect_id  = symbol.effect_id,
            is_triple  = is_triple,
            symbol     = symbol,
        })
    end

    return symbol_apply_data
end

return M
