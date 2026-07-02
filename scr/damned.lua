local settings = require("scr.settings.game_settings")
local const    = require("scr.const.game_consts")
local MN       = require("scr.const.message_names")
local log      = require("log.log")

local M        = {}

M.__index      = M

function M.new(url, config_id)
    local self           = setmetatable({}, M)

    local config         = settings.damned[config_id];
    self.url             = url
    self.url_gui         = msg.url("/gui#damned")
    self.max_health      = config.health
    self.health          = config.health
    self.p_dmg           = config.p_dmg
    self.m_dmg           = config.m_dmg
    self.is_dead         = false
    self.on_attack_done  = nil
    self.on_attack_apply = nil
    self.on_dead         = nil

    msg.post(self.url_gui, MN.set_progress, { value = 1.0 })

    return self
end

-- function M:apply_effect(effect, value)
--     if effect == const.effects.p_dmg then
--         self:get_damage(value)
--     end
-- end

function M:get_damage(amount)
    if self.is_dead then
        return
    end

    self.health = math.max(0, self.health - amount)

    local progress_01 = self.health / self.max_health
    msg.post(self.url_gui, MN.set_progress, { value = progress_01, animate = false })

    log:debug("Get damage:" .. amount .. ". Current health: " .. self.health)
    if self.health <= 0 then
        self.is_dead = true
        log:debug("Dead")
        msg.post(self.url, MN.dead)

        if self.on_dead then
            self.on_dead()
        end
    else
        msg.post(self.url, MN.take_damage, { value = amount })
    end
end

-- start attack
function M:attack()
    msg.post(self.url, MN.attack)
end

-- full attack completed
function M:finish_attack()
    if self.on_attack_done then
        self.on_attack_done()
    end
end

-- single attack in ative point
function M:apply_attack()
    if self.on_attack_apply then
        self.on_attack_apply(self.p_dmg)
    end
end

return M
