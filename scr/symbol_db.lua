local M = {}

M.symbols = {
    DAGGER = { id = "DAGGER", icon = "dagger", type = "attack", value = 15 },
    SHIELD = { id = "SHIELD", icon = "shield", type = "defend", value = 10 },
    COIN   = { id = "COIN", icon = "coin", type = "gold", value = 5 },
    POTION = { id = "POTION", icon = "potion", type = "heal", value = 20 },
    POISON = { id = "POISON", icon = "poison", type = "debuff", value = 8 },
    SKULL  = { id = "SKULL", icon = "skull", type = "attack", value = 30 },
}

-- Which symbols are in the player's reel pool (built via meta-progression)
M.player_pool = {
    M.symbols.DAGGER,
    M.symbols.DAGGER,
    M.symbols.SHIELD,
    M.symbols.COIN,
    M.symbols.POTION,
}

return M
