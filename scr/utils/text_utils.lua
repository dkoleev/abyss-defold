local M = {}

-- Replaces {key} placeholders in a description string with values from a table
-- "+{bd_per_damned} BD for every Damned symbol" -> "+2 BD for every Damned symbol"
function M.interpolate(template, values)
    -- Ensure we have a valid string and table to prevent runtime crashes
    if type(template) ~= "string" then return "" end
    if type(values) ~= "table" then return template end

    -- Using [_%w]+ allows underscores in key names (e.g., {first_name})
    return (template:gsub("{([_%w]+)}", function(key)
        local v = values[key]

        if v == nil then
            return "{" .. key .. "}"
        elseif type(v) == "table" or type(v) == "function" then
            -- Optional safety check: prevent raw table/function pointer leaks
            return "{" .. key .. ":invalid_type}"
        end

        return tostring(v)
    end))
end

return M
