local M = {}

-- build flat array from named keys (named key -> indexed array)
-- registry must contains field index for sort by it
function M.build(registry)
    local result = {}
    for _, item in pairs(registry) do
        result[#result+1] = item
    end

    -- Sort by index so the initial order is deterministic (0..21)
    table.sort(result, function(a, b) return a.index < b.index  end)

    return result
end

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

--- Checks whether a table contains a given value.
---@param t table Array-style table to search.
---@param value any Value to search for (compared with `==`).
---@return boolean found True if the value exists anywhere in `t`.
function M.contains(t, value)
    return M.index_of(t, value) ~= nil
end

--- Checks whether an array-style table has no elements.
---@param t table Array-style table.
---@return boolean is_empty
function M.is_empty(t)
    return #t == 0
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

--- Creates a deep copy of a table, recursively copying any nested tables.
--- Does not handle cyclic references (a table that contains itself, directly
--- or indirectly, will cause infinite recursion).
---@param original table Table to copy.
---@return table copy New table, fully independent of the original.
function M.copy_deep(original)
    local copy = {}
    for key, value in pairs(original) do
        if type(value) == "table" then
            copy[key] = M.copy_deep(value)
        else
            copy[key] = value
        end
    end
    return copy
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

--- Returns a new array-style table containing only the elements for which
--- `predicate` returns true. Does not mutate the original table.
--- M.filter(self.rings, function(r) return r.rarity == "Relic" end)
---@param t table Array-style table to filter.
---@param predicate fun(value: any, index: integer): boolean
---@return table filtered New table with matching elements, in original order.
function M.filter(t, predicate)
    local result = {}
    for i, v in ipairs(t) do
        if predicate(v, i) then
            table.insert(result, v)
        end
    end
    return result
end

--- Returns a new array-style table with `fn` applied to every element.
--- Does not mutate the original table.
---@param t table Array-style table to transform.
---@param fn fun(value: any, index: integer): any
---@return table mapped New table with transformed elements, in original order.
function M.map(t, fn)
    local result = {}
    for i, v in ipairs(t) do
        result[i] = fn(v, i)
    end
    return result
end

--- Finds the first element for which `predicate` returns true.
---@param t table Array-style table to search.
---@param predicate fun(value: any, index: integer): boolean
---@return any|nil value The first matching element, or nil if none match.
---@return integer|nil index The index of the matching element, or nil if none match.
function M.find(t, predicate)
    for i, v in ipairs(t) do
        if predicate(v, i) then
            return v, i
        end
    end
    return nil, nil
end

--- Removes and returns a random element from an array-style table.
--- Useful for things like drawing a random Damned/enemy from a pool.
---@param t table Array-style table to draw from.
---@return any|nil value The removed element, or nil if `t` was empty.
function M.take_random(t)
    if #t == 0 then return nil end
    local i = math.random(#t)
    local value = t[i]
    table.remove(t, i)
    return value
end

--- Removes and returns a random element from an array-style table, where
--- each element's selection probability is proportional to its weight.
--- Useful for weighted symbol/Damned pools (e.g. Relic rarer than Damned).
---@param t table Array-style table to draw from.
---@param weights table Array-style table of weights, same length as `t` and aligned by index (weights[i] is the weight for t[i]). Weights should be positive numbers; do not need to sum to 1.
---@return any|nil value The removed element, or nil if `t` was empty.
function M.take_random_weighted(t, weights)
    if #t == 0 then return nil end

    local total_weight = 0
    for i = 1, #t do
        total_weight = total_weight + weights[i]
    end

    local roll = math.random() * total_weight
    local cumulative = 0

    for i = 1, #t do
        cumulative = cumulative + weights[i]
        if roll <= cumulative then
            local value = t[i]
            table.remove(t, i)
            table.remove(weights, i)
            return value
        end
    end

    -- Fallback for floating point edge cases (roll lands exactly on total_weight)
    local last_index = #t
    local value = t[last_index]
    table.remove(t, last_index)
    table.remove(weights, last_index)
    return value
end

--- Use it if elemnts of table contains weights as a field
--- M.take_random_weighted_by(self.symbol_pool, function(s) return s.drop_weight end)
---@param t table Array-style table to draw from.
---@param weight_fn fun(value: any): number Function returning the weight for a given element.
---@return any|nil value
function M.take_random_weighted_by(t, weight_fn)
    if #t == 0 then return nil end

    local total_weight = 0
    for i = 1, #t do
        total_weight = total_weight + weight_fn(t[i])
    end

    local roll = math.random() * total_weight
    local cumulative = 0

    for i = 1, #t do
        cumulative = cumulative + weight_fn(t[i])
        if roll <= cumulative then
            local value = t[i]
            table.remove(t, i)
            return value
        end
    end

    local last_index = #t
    local value = t[last_index]
    table.remove(t, last_index)
    return value
end

--- Shuffles an array-style table in place using the Fisher-Yates algorithm.
--- Mutates `t` directly and also returns it for convenient chaining.
--- Call M.shuffle(M.copy_shallow(t)) if you don't want mutate the original table
---@param t table Array-style table to shuffle.
---@return table t The same table, shuffled.
function M.shuffle(t)
    for i = #t, 2, -1 do
        local j = math.random(i)
        t[i], t[j] = t[j], t[i]
    end
    return t
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

return M
