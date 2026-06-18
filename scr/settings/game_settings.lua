local const = require("scr.const.game_consts")

local M = {}

M.battle = {
    damned_factory_url = "/factories#damned_factory"
}

M.damned_spawn_pool = {
    const.damned.demon_eye,
    const.damned.plague_fly,
    const.damned.skull,
}

M.damned = {
    [const.damned.demon_eye] = {
        url = "/battle/damned/demon_eye/demon_eye.goc", -- .goc because use dymanic prototype
        factory_url = "/factories#damned_demon_eye_factory",
        health = 100,
        p_dmg = 0,
        m_dmg = 10
    },
    [const.damned.plague_fly] = {
        url = "/battle/damned/plague_fly/plague_fly.goc",
        factory_url = "/factories#damned_plague_fly_factory",
        health = 50,
        p_dmg = 5,
        m_dmg = 0
    },
    [const.damned.skull] = {
        url = "/battle/damned/skull/skull.goc",
        factory_url = "/factories#damned_skull_factory",
        health = 150,
        p_dmg = 10,
        m_dmg = 0
    }
}

return M
