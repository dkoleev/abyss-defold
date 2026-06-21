local const = require("scr.const.game_consts")

local M = {}

M.battle = {
    damned_factory_url = "/factories#damned_factory"
}

M.player = {
    health = 100
}

M.levels = {
    level_0 = {
        factory_url = "/factories#level_1_collectionproxy"
    }
}

M.effects = {
    [const.effects.p_dmg] = {
        type = "active",
        duration = 0.6
    }
}

M.symbols = {
    DAGGER = { id = "DAGGER", icon = "dagger", type = "attack", value = 15, effect_id = const.effects.p_dmg },
    SHIELD = { id = "SHIELD", icon = "shield", type = "defend", value = 10, effect_id = const.effects.p_dmg },
    COIN   = { id = "COIN", icon = "coin", type = "gold", value = 5, effect_id = const.effects.p_dmg },
    POTION = { id = "POTION", icon = "potion", type = "heal", value = 20, effect_id = const.effects.p_dmg },
    POISON = { id = "POISON", icon = "poison", type = "debuff", value = 8, effect_id = const.effects.p_dmg },
    SKULL  = { id = "SKULL", icon = "skull", type = "attack", value = 30, effect_id = const.effects.p_dmg },
}

-- Which symbols are in the player's reel pool (built via meta-progression)
M.symbols_spawn_pool = {
    M.symbols.DAGGER,
    M.symbols.DAGGER,
    M.symbols.SHIELD,
    M.symbols.COIN,
    M.symbols.POTION,
}

M.damned = {
    [const.damned.demon_eye] = {
        factory_url = "/factories#damned_demon_eye_factory",
        health = 100,
        p_dmg = 0,
        m_dmg = 10
    },
    [const.damned.plague_fly] = {
        factory_url = "/factories#damned_plague_fly_factory",
        health = 80,
        p_dmg = 5,
        m_dmg = 0
    },
    [const.damned.skull] = {
        factory_url = "/factories#damned_skull_factory",
        health = 150,
        p_dmg = 10,
        m_dmg = 0
    }
}

M.damned_spawn_pool = {
    const.damned.demon_eye,
    const.damned.plague_fly,
    const.damned.skull,
}

return M
