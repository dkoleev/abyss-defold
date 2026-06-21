local settings = require("scr.settings.game_settings")
local const    = require("scr.const.game_consts")
local MN       = require("scr.const.message_names")

local M        = {}

M.__index      = M

function M.new(url, config_id)
    local self      = setmetatable({}, M)

    local config    = settings.damned[config_id];
    self.url        = url
    self.max_health = config.health
    self.health     = config.health
    self.p_dmg      = config.p_dmg
    self.m_dmg      = config.m_dmg
    self.is_dead    = false;

    return self
end

function M:apply_effect(effect, value)
    if effect == const.effects.p_dmg then
        self:take_damage(value)
    end
end

function M:take_damage(amount)
    if self.is_dead then
        return
    end

    self.health = math.max(0, self.health - amount)
    if self.health <= 0 then
        self.is_dead = true
        msg.post(self.url, MN.dead)
    else
        msg.post(self.url, MN.take_damage)
    end
end

function M:attack()

end

return M
