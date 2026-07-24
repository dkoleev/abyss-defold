local M = {}

M.__index = M

--==================== PUBLIC API ===================================

function M.new(url, config_id)
    local self = setmetatable({
        url = url,
        config_id = config_id
    }, M)

    return self
end

function M:on_inpunt(action_id, action)
    
end

--===================================================================

return M