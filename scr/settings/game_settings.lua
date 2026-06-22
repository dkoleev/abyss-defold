local const = require("scr.const.game_consts")
local ring_rarity = const.ring_rarity

local M = {}

M.battle = {
    damned_factory_url = "/factories#damned_factory",
}

M.player = {
    health = 100
}

M.slot_machine = {
    default_reels_count = 3
}

M.levels = {
    level_0 = {
        factory_url = "/factories#level_1_collectionproxy"
    }
}

--======================= SYMBOLS ==============================================

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

M.effects = {
    [const.effects.p_dmg] = {
        type = "active",
        duration = 0.6
    }
}

--======================== RINGS ================================================

M.rings = {
    footmen = {
        order = 1,
        rarity = ring_rarity.common,
        name = "Ring of Footmen",
        description = "+%d BD for every Damned-tier symbol landed this spin.",
        cost = 3,
        values = { bd_per_dagger = 2 },
    },
    watcher = {
        order = 2,
        rarity = ring_rarity.common,
        name = "Ring of the Watcher",
        description = "+%d SoulsMult every 3 spins (caps at +%d).",
        cost = 4,
        values = { mult_step = 1, spin_interval = 3, cap = 5 },
    },
    frail_iron = {
        order = 5,
        rarity = ring_rarity.common,
        name = "Ring of Frail Iron",
        description = "+%d DamageMult, but -%d max Ring slot.",
        cost = 5,
        values = { dmg_mult = 1, slot_penalty = 1 },
    },
}

--======================== DAMNED ====================================================
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
--==============================================================================

return M
