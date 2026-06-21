local MN = require("scr.const.message_names")
local settings = require("scr.settings.game_settings")

local M = {}
M.__index = M

local function evaluate(results, self)
    local counts = {}
    for _, sym in ipairs(results) do
        counts[sym.id] = (counts[sym.id] or 0) + 1
    end

    local symbol_apply_data = {}
    for reel_index, symbol in ipairs(results) do
        local is_triple = counts[symbol.id] == self.reels_count;
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

--================= PUBLIC API ========================
--=====================================================

function M.new(url, reels_count)
    local self = setmetatable({
        url          = url,
        results      = {},
        stopped      = 0,
        spinning     = false,
        on_spin_done = nil,
        reels_count  = reels_count
    }, M)

    return self
end

function M:spin()
    self.results = {}
    self.stopped = 0
    self.spinning = true

    msg.post(self.url, MN.start_spin)
end

function M:stop_next_reel()
    local reel_2_stop = self.stopped + 1
    if self.spinning and reel_2_stop <= self.reels_count then
        msg.post(self.url, MN.stop_reel, {
            reel_index = reel_2_stop
        })
    end
end

-- Call from parent script's on_message
function M:on_reel_stopped(message)
    self.results[message.reel_index] = message.symbol
    self.stopped = self.stopped + 1

    if self.stopped == self.reels_count then
        self.spinning = false
        local outcome = evaluate(self.results, self)
        if self.on_spin_done then
            self.on_spin_done(outcome)
        end
    end
end

return M
