return {
    damned = {
        demon_eye = hash("demon_eye"),
        plague_fly = hash("plague_fly"),
        skull = hash("skull"),
    },

    effects = {
        p_dmg = hash("p_dmg"),
        m_dmg = hash("m_dmg"),
        heal = hash("heal")
    },

    ring_rarity = {
        common    = 1,   --men
        uncommon  = 2,   --dwarves
        rare      = 3,   --elves
        legendary = 4    --one ring
    },

    ring_rarity_names = {
        "Common",
        "Uncommon",
        "Rare",
        "Legendary"
    } --usecase: print(ring_rarity_names[M.rings.footmen.rarity]) -- Outputs: Common
}
