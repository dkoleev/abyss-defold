local text_utils = require("scr.utils.text_utils")
local settings   = require("scr.settings.game_settings")
local MN = require("scr.const.message_names")

local M          = {}
M.__index        = M

function M.new(url, config_id)
    local self     = setmetatable({}, M)

    local config   = settings.rings[config_id]

    self.config_id = config_id
    self.url       = url

    self.values    = config.values
    self.state     = {}

    -- Create a brand new table for runtime state
    -- if config and config.values then
    --     for k, v in pairs(config.values) do
    --         self.values[k] = v
    --         -- Note: If 'v' is ever another table, you'd need a deep copy function here instead!
    --     end
    -- end

    return self
end

function M:delete()
    msg.post(self.url, MN.delete)
end

-- based on config values
function M:get_description()
    local config = settings.rings[self.config_id]
    return text_utils.interpolate(config.description, config.values)
end

-- based on merged state and config values (state values in priority)
function M:get_dynamic_description()
    local config = settings.rings[self.config_id]
    local merged = {}
    for k, v in pairs(config.values or {}) do merged[k] = v end
    for k, v in pairs(self.state or {}) do merged[k] = v end

    return text_utils.interpolate(config.description, merged)
end

return M
