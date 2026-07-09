local table_utils = require("scr.utils.table_utils")
local settings    = require("scr.settings.game_settings")

local M           = {}

M.__index         = M

function M.new()
    local self = setmetatable({
        draw_pile = {},
        discard   = {}
    }, M)

    return self
end

function M:build(registry)
    self.draw_pile = table_utils.build(registry)
    self:shuffle()
end

function M:shuffle()
    table_utils.shuffle(self.draw_pile)
end

function M:draw_card()
    if #self.draw_pile == 0 then
        self.draw_pile = self.discard
        self.discard   = {}
        self:shuffle()
    end

    return table.remove(self.draw_pile)
end

function M:discard_card(card)
    table.insert(self.discard, card)
end

return M
