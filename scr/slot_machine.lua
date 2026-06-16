local MN = require("scr.const.message_names")

local M = {}

local REEL_COUNT = 3

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
            self.on_spin_done(outcome)
        end
    end
end

-- Evaluate result table → outcome
function M.evaluate(results)
    local counts = {}
    for _, sym in ipairs(results) do
        counts[sym.id] = (counts[sym.id] or 0) + 1
    end

    local effects = {}
    for id, count in pairs(counts) do
        local sym = results[1] -- grab a reference for type/value
        -- find first matching symbol for data
        for _, s in ipairs(results) do
            if s.id == id then
                sym = s; break
            end
        end

        local multiplier = (count == REEL_COUNT) and 2 or 1 -- triple = bonus
        table.insert(effects, {
            type      = sym.type,
            value     = sym.value * count * multiplier,
            is_triple = (count == REEL_COUNT),
            symbol    = sym,
        })
    end

    return effects -- list of {type, value, is_triple, symbol}
end

return M
