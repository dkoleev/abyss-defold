local M = {}

--- Finds the index of the first occurrence of a value in an array-style table.
---@param t table Array-style table to search.
---@param value any Value to search for (compared with `==`).
---@return integer|nil index Index of the first match, or nil if not found.
function M.index_of(t, value)
    for i, v in ipairs(t) do
        if v == value then return i end
    end
    return nil
end

--- Creates a shallow copy of a table. Nested tables are shared by reference,
--- not duplicated — mutating a nested table in the copy also affects the original.
---@param original table Table to copy.
---@return table copy New table with the same top-level key/value pairs.
function M.copy_shallow(original)
    local copy = {}
    for key, value in pairs(original) do
        copy[key] = value
    end

    return copy
end

--- Prints all key/value pairs of a table using the given log function.
--- Intended for quick debugging, not for use on deeply nested tables (does not recurse).
---@param t table Table to print.
---@param log_fn function|nil Optional logging function with signature `fn(message: string)`. Defaults to `print`.
function M.print_table(t, log_fn)
    log_fn = log_fn or print
    for key, value in pairs(t) do
        log_fn(tostring(key) .. " : " .. tostring(value))
    end
end

--- Removes the first occurrence of a value from an array-style table.
--- Safe to use on sequences (contiguous integer keys starting at 1) — uses
--- `table.remove` internally, which shifts subsequent elements down by one.
---@param t table Array-style table to remove from.
---@param value any Value to remove (compared with `==`).
---@return boolean removed True if a matching value was found and removed.
function M.remove_value_from_array(t, value)
    local i = M.index_of(t, value)
    if not i then return false end
    table.remove(t, i)
    return true
end

--- Removes the first key/value pair whose value matches, from a hash-map-style table.
--- Sets the matching key to `nil` directly — does not shift or reindex anything,
--- which is correct for non-sequential/hash tables (unlike `table.remove`).
---@param t table Hash-map-style table to remove from.
---@param value any Value to remove (compared with `==`).
---@return boolean removed True if a matching value was found and removed.
function M.remove_value_from_hash_map(t, value)
    for key, cur_value in pairs(t) do
        if cur_value == value then
            t[key] = nil
            return true
        end
    end
    return false
end

return M