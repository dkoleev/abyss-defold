local rings_behavior = require("scr.rings_behaviour")

local M = {}

function M.fire_event(held_rings, event_name, context)
    context.event = event_name
    for _, ring in ipairs(held_rings) do
        local behavior = rings_behavior[ring.id]
        if behavior then
            behavior(ring, context)
        end
    end
    return context
end

return M
