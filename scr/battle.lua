local settings = require("scr.settings.game_settings")
local proxy_loader = require("scr.utils.proxy_loader")
local message_names = require("scr.const.message_names")

local M = {}

function M.apply_slot_machine_symbols(symbols_apply_data, index)
    -- Start at the first symbol if no index is provided
    index = index or 1

    -- Base case: if we've processed all symbols, stop
    if index > #symbols_apply_data then
        return
    end

    local symbol = symbols_apply_data[index]

    -- Apply the current symbol effect
    msg.post(M.current_damned, message_names.apply_effect, {
        effect = symbol.effect_id,
        value = symbol.value
    })

    local effect_config = settings.effects[symbol.effect_id]

    timer.delay(effect_config.duration, false, function()
        M.apply_slot_machine_symbols(symbols_apply_data, index + 1)
    end)
end

function M.spawn_damned()
    local damned_id = settings.damned_spawn_pool[math.random(#settings.damned_spawn_pool)]
    local damned_config = settings.damned[damned_id];

    M.current_damned = factory.create(damned_config.factory_url, nil, nil, {
        config_id = damned_id
    })
end


function M.init()
    M.current_damned = nil

    proxy_loader.load(settings.levels.level_0.factory_url, {
        enable = true,
        acquire_input = true,
        on_loaded = function(url)
            M.spawn_damned()
        end
    })
end

function M.on_message(message_id, message, sender)
    proxy_loader.on_message(message_id, message, sender)
end

return M
