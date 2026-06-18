local settings = require("scr.settings.game_settings")

local M = {}

function M.init()
    M.current_damned = nil
    M.spawn_damned()
end

function M.spawn_damned()

    local damned_id = settings.damned_spawn_pool[math.random(#settings.damned_spawn_pool)]
    local damned_config = settings.damned[damned_id];
    print(damned_config.url, damned_config.factory_url)
    factory.create(damned_config.factory_url)

    -- factory.unload(settings.battle.damned_factory_url)
    -- factory.set_prototype(settings.battle.damned_factory_url, damned_config.url)
    -- factory.load(settings.battle.damned_factory_url, function(self, url, result)
    --     print("xxxx", url)
    --     if result then
    --         factory.create(url)
    --     else
    --         print("Failed to load prototype:", damned_config.url)
    --     end
    -- end)
end

return M
