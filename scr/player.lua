local settings = require("scr.settings.game_settings")
local log      = require("log.log")

local M        = {}
M.__index      = M

function M.new()
    local self = setmetatable({
        health = settings.player.health,
        is_dead = false,
        on_dead = nil
    }, M)

    return self
end

function M:get_damage(amount)
    self.health = math.max(0, self.health - amount)

    log:debug("Get damage:" .. amount .. ". Current health: " .. self.health)

    if self.health <= 0 then
        self.is_dead = true
        if self.on_dead then
            self.on_dead()
        end
        log:debug("Dead")
    end
end

return M
