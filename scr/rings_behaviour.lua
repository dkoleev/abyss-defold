local consts      = require("scr.const.game_consts")
local ring_rarity = consts.ring_rarity
local log         = require("log.log")

local M           = {}

M.footmen         = function(ring, context)
    if context.event == "on_symbol_resolved" then
        if context.symbol.id == "DAGGER" then
            context.bd = context.bd + ring.values.bd_per_dagger

            log:debug("[APPLY RING]: footmen. event: " .. context.event .. " ring value: " ..
                ring.values.bd_per_dagger .. "; bd new value: " .. context.bd)
        end
    end
end

M.watcher         = function(ring, context)
    if context.event == "on_spin_end" then
        ring.state.spins = (ring.state.spins or 0) + 1
        if ring.state.spins % ring.values.spin_interval == 0 then
            ring.state.bonus_mult = math.min(ring.values.cap,
                (ring.state.bonus_mult or 0) + ring.values.mult_step)
        end
    elseif context.event == "on_apply_mult" then
        context.souls_mult = context.souls_mult + (ring.state.bonus_mult or 0)
    end

    log:debug("[APPLY RING]: watcher. event: " .. context.event);
end

M.frail_iron      = function(ring, context)
    if context.event == "on_apply_mult" then
        context.dmg_mult = context.dmg_mult + ring.values.dmg_mult
    elseif context.event == "on_acquired" then
        context.max_ring_slots = context.max_ring_slots - ring.values.slot_penalty
    end

    log:debug("[APPLY RING]: frail_iron. event: " .. context.event);
end

return M
