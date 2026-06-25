local rings_behavior = require("scr.rings_behaviour")
local log            = require("log.log")

local M              = {}

--- Fires an event through all held rings in slot order (ONE unified pass).
--- This preserves the Balatro-style guarantee: ring slot order determines
--- the final accumulator values, because each ring's effect is applied
--- immediately, using whatever earlier rings already wrote to context.
-- @param held_rings table: ordered array of ring instances, slot order matters
-- @param event_name string
-- @param context table: must already contain any accumulator fields the
--   caller wants seeded before this pass (e.g. context.dmg_mult = 1),
--   since apply_effect only initializes missing fields to a default
--   (0 for additive, 1 for multiplicative) the first time they're touched.
function M.fire_event(held_rings, context, score_state)

    for _, ring in ipairs(held_rings) do
        local behaviour = rings_behavior[ring.config_id]
        if behaviour then
            local effect = behaviour(ring, context)
            if effect then
                -- THIS is the order-dependent part.
                -- +mult effects: additive on the current mult
                if effect.mult then
                    score_state.mult = score_state.mult + effect.mult
                end

                -- xmult effects: multiplicative on the CURRENT mult,
                -- i.e. whatever +mult has already been added by earlier rings
                -- in the slot order gets multiplied too.
                if effect.xmult then
                    score_state.mult = score_state.mult * effect.xmult
                end

                -- wounds are a fully separate accumulator -- xmult never touches them
                if effect.wounds then
                    score_state.wounds = score_state.wounds + effect.wounds
                end
            end
        end
    end

    log:debug("[RINGS]: fire event [" .. context.event .. "]. new score_state: ", score_state)

    return score_state
end

return M
