local const = require("scr.const.game_consts")
local ring_rarity = const.ring_rarity

local M = {}

M.battle = {
    damned_factory_url = "/factories#damned_factory",
    durations = {
        add_symbol_value_to_result = 0.2,
        add_ring_value_to_result = 0.2,
        apply_damage_to_damned = 1
    }
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
    DAGGER = { id = "DAGGER", icon = "dagger", type = "attack", value = 5 },
    SHIELD = { id = "SHIELD", icon = "shield", type = "defend", value = 3 },
    COIN   = { id = "COIN", icon = "coin", type = "gold", value = 5 },
    POTION = { id = "POTION", icon = "potion", type = "heal", value = 8 },
    POISON = { id = "POISON", icon = "poison", type = "debuff", value = 4 },
    SKULL  = { id = "SKULL", icon = "skull", type = "attack", value = 5 }
}

-- Which symbols are in the player's reel pool (built via meta-progression)
M.symbols_spawn_pool = {
    M.symbols.DAGGER,
    M.symbols.DAGGER,
    M.symbols.SHIELD,
    M.symbols.COIN,
    M.symbols.POTION,
}

--======================== TAROT ================================================

M.tarot = {
    fool             = { index = 0, id = "fool", name = "fool", sprite = "fool" },
    magician         = { index = 1, id = "", name = "", sprite = "" },
    high_priestess   = { index = 2, id = "", name = "", sprite = "" },
    empress          = { index = 3, id = "", name = "", sprite = "" },
    emperor          = { index = 4, id = "", name = "", sprite = "" },
    hierophant       = { index = 5, id = "", name = "", sprite = "" },
    lovers           = { index = 6, id = "", name = "", sprite = "" },
    chariot          = { index = 7, id = "", name = "", sprite = "" },
    strength         = { index = 8, id = "", name = "", sprite = "" },
    hermit           = { index = 9, id = "", name = "", sprite = "" },
    wheel_of_fortune = { index = 10, id = "", name = "", sprite = "" },
    justice          = { index = 11, id = "", name = "", sprite = "" },
    hanged_men       = { index = 12, id = "", name = "", sprite = "" },
    death            = { index = 13, id = "", name = "", sprite = "" },
    temperance       = { index = 14, id = "", name = "", sprite = "" },
    devil            = { index = 15, id = "", name = "", sprite = "" },
    tower            = { index = 16, id = "", name = "", sprite = "" },
    star             = { index = 17, id = "", name = "", sprite = "" },
    moon             = { index = 18, id = "", name = "", sprite = "" },
    sun              = { index = 19, id = "", name = "", sprite = "" },
    judgment         = { index = 20, id = "", name = "", sprite = "" },
    world            = { index = 21, id = "", name = "", sprite = "" }
}

--======================== ZODIAC ===============================================

M.zodiac = {
    
}

--======================== RINGS ================================================
-- description: show by text_utils.interpolate(description, values) if static (not need dynamic values from state)

M.rings = {
    skull_blood = {
        id = "skull_blood",
        order = 1,
        factory_url = "/rings_factories#ring_skull_blood_factory",
        rarity = ring_rarity.common,
        name = "Ring of Skull Blood",
        description = "x{xmult} for every symbol landed this spin.",
        cost = 3,
        values = { xmult = 1.2 },
    },
    -- footmen = {
    --     id = "footmen",
    --     order = 1,
    --     factory_url = "/rings_factories#ring_1_factory",
    --     rarity = ring_rarity.common,
    --     name = "Ring of Footmen",
    --     description = "+{bd_per_dagger} BD for every Damned-tier symbol landed this spin.",
    --     cost = 3,
    --     values = { bd_per_dagger = 2 },
    -- },
    -- watcher = {
    --     id = "watcher",
    --     order = 2,
    --     factory_url = "/rings_factories#ring_1_factory",
    --     rarity = ring_rarity.common,
    --     name = "Ring of the Watcher",
    --     description = "+{mult_step} SoulsMult every {spin_interval} spins (caps at +{cap}).",
    --     cost = 4,
    --     values = { mult_step = 1, spin_interval = 3, cap = 5 },
    -- },
    -- frail_iron = {
    --     id = "frail_iron",
    --     order = 5,
    --     factory_url = "/rings_factories#ring_1_factory",
    --     rarity = ring_rarity.common,
    --     name = "Ring of Frail Iron",
    --     description = "+{dmg_mult} DamageMult, but -{slot_penalty} max Ring slot.",
    --     cost = 5,
    --     values = { dmg_mult = 1, slot_penalty = 1 },
    -- },
}

--======================== DAMNED ====================================================
M.damned = {
    demon_eye = {
        id = "demon_eye",
        factory_url = "/factories#damned_demon_eye_factory",
        health = 100,
        p_dmg = 0,
        m_dmg = 10
    },
    plague_fly = {
        id = "plague_fly",
        factory_url = "/factories#damned_plague_fly_factory",
        health = 80,
        p_dmg = 5,
        m_dmg = 0
    },
    skull = {
        id = "skull",
        factory_url = "/factories#damned_skull_factory",
        health = 150,
        p_dmg = 10,
        m_dmg = 0
    }
}

M.damned_spawn_pool = {
    M.damned.demon_eye.id,
    M.damned.demon_eye.id,
    M.damned.skull.id
}
--==============================================================================

return M
