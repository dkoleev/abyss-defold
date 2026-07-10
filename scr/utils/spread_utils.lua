-- spread_layout.lua
-- Computes positions and rotations for a hand of cards fanned around a center point.
-- All positions are in world space relative to a spawn point.

local M = {}

--- @class SpreadConfig
--- @field max_spread number      max total width in pixels (e.g. 600)
--- @field card_width number      card width in pixels
--- @field arc_depth number       how much center cards rise (e.g. 40)
--- @field max_rotation number    max rotation in degrees at the edges (e.g. 20)
--- @field card_overlap number    min overlap when there are many cards (0..1)

--- Default config — tweak to match your card size and taste
M.default_config = {
    max_spread   = 600,
    card_width   = 64,
    arc_depth    = 10,
    max_rotation = 10,
    card_overlap = 0.3, -- cards start overlapping when spread gets tight
}

--- Returns the effective spread width, narrowing when there are few cards.
--- Mirrors Balatro: a hand of 1 takes no width, a full hand takes max_spread.
local function get_spread_width(count, config)
    if count <= 1 then return 0 end
    -- Scale spread with card count, capped at max
    local natural = config.card_width * count * (1 - config.card_overlap)
    return math.min(natural, config.max_spread)
end

--- Returns normalized position t in [-0.5, 0.5] for card at index i (1-based)
--- in a hand of `count` cards.
local function normalized_t(i, count)
    if count == 1 then return 0 end
    return (i - 1) / (count - 1) - 0.5
end

--- Compute layout for all cards in the spread.
--- Returns a list of {x, y, rotation} offsets from the spawn point.
---
--- @param count number          number of cards
--- @param config SpreadConfig | nil   layout config (or nil for defaults)
--- @return table[]              list of {x, y, rotation} for each card
function M.compute(count, config)
    config = config or M.default_config
    local spread = get_spread_width(count, config)
    local result = {}

    for i = 1, count do
        local t = normalized_t(i, count)

        -- x: linear spread from -spread/2 to +spread/2
        local x = t * spread

        -- y: parabolic arc — edges dip, center rises
        -- t=0 (center) → y=0, t=±0.5 → y=-arc_depth
        -- local y = -(1 - (2 * t) ^ 2) * config.arc_depth
        local y = -(2 * t) ^ 2 * config.arc_depth

        -- rotation: linear from -max_rotation to +max_rotation
        local rotation = - t * config.arc_depth * 2 -- in degrees
        -- clamp
        rotation = math.max(-config.max_rotation, math.min(config.max_rotation, rotation))


        result[i] = { x = x, y = y, rotation = rotation }
    end

    return result
end

return M
