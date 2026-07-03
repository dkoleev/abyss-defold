local M                      = {}
M.__index                    = M

function M.new()
    local self = setmetatable({
        url                = msg.url(),
        state              = nil,
        damned_url         = nil,
        damned_model       = nil,
        player_url         = nil,
        player_model       = nil,
        rings              = {}
    }, M)

    return self
end
