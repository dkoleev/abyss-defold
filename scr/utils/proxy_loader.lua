--- proxy_loader.lua
--- Universal helper for loading/unloading Defold collection proxies with callbacks.
---
--- IMPORTANT: the script that owns the collectionproxy component must forward
--- its on_message to proxy_loader.on_message, because the engine replies with
--- "proxy_loaded" / "proxy_unloaded" to whoever sent the original "load" /
--- "unload" message — not to this module.
---
--- Usage:
---   local proxy_loader = require("scr.util.proxy_loader")
---
---   proxy_loader.load(battle_proxy_url, {
---       enable = true,
---       acquire_input = true,
---       on_loaded = function(url) ... end,
---   })
---
---   proxy_loader.unload(battle_proxy_url, {
---       on_unloaded = function(url) ... end,
---   })
---
---   function on_message(self, message_id, message, sender)
---       proxy_loader.on_message(message_id, message, sender)
---   end

local M                  = {}

local STATE_UNLOADED     = "unloaded"
local STATE_LOADING      = "loading"
local STATE_LOADED       = "loaded"
local STATE_UNLOADING    = "unloading"

local MSG_LOAD           = hash("load")
local MSG_UNLOAD         = hash("unload")
local MSG_ENABLE         = hash("enable")
local MSG_DISABLE        = hash("disable")
local MSG_ACQUIRE_INPUT  = hash("acquire_input_focus")
local MSG_RELEASE_INPUT  = hash("release_input_focus")
local MSG_PROXY_LOADED   = hash("proxy_loaded")
local MSG_PROXY_UNLOADED = hash("proxy_unloaded")

---@class ProxyLoaderEntry
---@field url url
---@field state string
---@field on_loaded fun(url: url)|nil
---@field on_unloaded fun(url: url)|nil
---@field enable boolean|nil
---@field acquire_input boolean|nil

---@type table<string, ProxyLoaderEntry>
local entries            = {}

---@param proxy_url string|hash
---@return string
local function key_of(proxy_url)
    return tostring(msg.url(proxy_url))
end

--- Start loading a collection proxy.
--- Safe to call repeatedly: a load already in progress or finished is a no-op.
---@param proxy_url string|hash
---@param options table|nil  { enable: boolean, acquire_input: boolean, on_loaded: fun(url) }
function M.load(proxy_url, options)
    options = options or {}
    local url = msg.url(proxy_url)
    local key = key_of(url)

    local existing = entries[key]
    if existing and (existing.state == STATE_LOADING or existing.state == STATE_LOADED) then
        print(("proxy_loader: '%s' is already %s, ignoring load()"):format(key, existing.state))
        return
    end

    entries[key] = {
        url = url,
        state = STATE_LOADING,
        on_loaded = options.on_loaded,
        on_unloaded = options.on_unloaded,
        enable = options.enable,
        acquire_input = options.acquire_input,
    }

    msg.post(url, MSG_LOAD)
end

--- Start unloading a previously loaded collection proxy.
---@param proxy_url string|hash
---@param options table|nil  { on_unloaded: fun(url) }
function M.unload(proxy_url, options)
    options = options or {}
    local url = msg.url(proxy_url)
    local key = key_of(url)

    local entry = entries[key]
    if not entry or entry.state ~= STATE_LOADED then
        print(("proxy_loader: '%s' is not loaded, ignoring unload()"):format(key))
        return
    end

    entry.state = STATE_UNLOADING
    entry.on_unloaded = options.on_unloaded or entry.on_unloaded

    if entry.acquire_input then
        msg.post(url, MSG_RELEASE_INPUT)
    end

    msg.post(url, MSG_UNLOAD)
end

---@param proxy_url string|hash
---@return string state  "unloaded" | "loading" | "loaded" | "unloading"
function M.get_state(proxy_url)
    local entry = entries[key_of(proxy_url)]
    return entry and entry.state or STATE_UNLOADED
end

---@param proxy_url string|hash
---@return boolean
function M.is_loaded(proxy_url)
    return M.get_state(proxy_url) == STATE_LOADED
end

--- Forward this from the owning script's on_message.
---@param message_id hash
---@param message table
---@param sender url
---@return boolean handled  true if this was a proxy_loaded/proxy_unloaded message handled here
function M.on_message(message_id, message, sender)
    local key = key_of(sender)
    local entry = entries[key]
    if not entry then
        return false
    end

    if message_id == MSG_PROXY_LOADED then
        entry.state = STATE_LOADED

        if entry.enable then
            msg.post(sender, MSG_ENABLE)
        end
        if entry.acquire_input then
            msg.post(sender, MSG_ACQUIRE_INPUT)
        end
        if entry.on_loaded then
            entry.on_loaded(entry.url)
        end
        return true
    elseif message_id == MSG_PROXY_UNLOADED then
        entry.state = STATE_UNLOADED
        local on_unloaded = entry.on_unloaded
        entries[key] = nil
        if on_unloaded then
            on_unloaded(sender)
        end
        return true
    end

    return false
end

return M
