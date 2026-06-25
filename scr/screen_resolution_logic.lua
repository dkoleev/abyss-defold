local defos = defos -- requires the DefOS native extension added to your project

local M = {}

-- ======== USAGE IN GUI =================

-- local settings = require("main.settings")

-- local function on_resolution_selected(self, index)
--     settings.set_resolution(index)
-- end

-- local function on_fullscreen_toggle(self, mode)
--     settings.set_display_mode(mode)
-- end
-- Wire these up to your dropdown/buttons in on_input or gui callbacks

--======================================================================

local SAVE_FILE = sys.get_save_file("abyss", "settings")

-- Common resolutions, you can expand this list
M.RESOLUTIONS_LANDSCAPE = {
    { width = 1280, height = 720 },
    { width = 1600, height = 900 },
    { width = 1920, height = 1080 },
    { width = 2560, height = 1440 },
    { width = 3840, height = 2160 },
}

M.RESOLUTIONS_PORTRAIT = {
    { height = 1280, width = 720 },
    { height = 1600, width = 900 },
    { height = 1920, width = 1080 },
    { height = 2560, width = 1440 },
    { height = 3840, width = 2160 },
}

local DEFAULT_SETTINGS = {
    resolution_index = 3,      -- defaults to 1920x1080
    display_mode = "windowed_fullscreen", -- "windowed", "windowed_fullscreen", "fullscreen"
}

local current = nil

function M.load()
    current = sys.load(SAVE_FILE)
    if not current or not current.resolution_index then
        current = DEFAULT_SETTINGS
    end
    return current
end

function M.save()
    sys.save(SAVE_FILE, current)
end

function M.get()
    return current
end

function M.apply()
    local res = M.RESOLUTIONS_LANDSCAPE[current.resolution_index]

    if current.display_mode == "fullscreen" then
        defos.set_fullscreen(true)
    elseif current.display_mode == "windowed_fullscreen" then
        defos.set_fullscreen(false)
        local displays = defos.get_displays()
        local current_id = defos.get_current_display_id()
        local display = displays[current_id]
        defos.set_window_size(nil, nil, display.bounds.width, display.bounds.height)
    else -- windowed
        defos.set_fullscreen(false)
        defos.set_window_size(nil, nil, res.width, res.height)
    end
end

function M.set_resolution(index)
    current.resolution_index = index
    M.apply()
    M.save()
end

function M.set_display_mode(mode)
    current.display_mode = mode
    M.apply()
    M.save()
end

return M
