local M = {}

M.__index = M

--==================== PUBLIC API ===================================

function M.new()
    local self = setmetatable({
        url = msg.url()
    }, M)

    return M
end

function M:on_inpunt(action_id, action)
    
end

--===================================================================

return M