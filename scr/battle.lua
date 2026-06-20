local settings = require("scr.settings.game_settings")
local proxy_loader = require("scr.utils.proxy_loader")

local M = {}

function M.apply_effect(target, effect)
    
end

function M.init()
    M.current_damned = nil

    proxy_loader.load(settings.levels.level_0.factory_url, {
		enable = true,
		acquire_input = true,
		on_loaded = function (url)
            M.spawn_damned()
		end
	})
end

function M.spawn_damned()
    local damned_id = settings.damned_spawn_pool[math.random(#settings.damned_spawn_pool)]
    local damned_config = settings.damned[damned_id];

    M.current_damned = factory.create(damned_config.factory_url, nil, nil, {
        config_id = damned_id
    })
end

function M.on_message(message_id, message, sender)
    proxy_loader.on_message(message_id, message, sender)
end

return M
