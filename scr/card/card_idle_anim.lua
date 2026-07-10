--- card_idle_anim.lua
--- Ports Balatro's ambient_tilt idle animation to Defold.
---
--- Balatro drives a "virtual cursor" in a circular orbit around the card.
--- The cursor position is fed to the tilt shader as a normalised (-1..1) offset.
--- We replicate this without a shader by converting the cursor offset into
--- go.set scale.x / scale.y / euler.z  so it works with plain sprites too.
---
--- Usage:
---   local idle_anim = require("modules.card_idle_anim")
---
---   function init(self)
---       idle_anim.init(self, card_id)   -- card_id: any unique integer per card
---   end
---
---   function update(self, dt)
---       idle_anim.update(self, dt)
---       idle_anim.apply(self)           -- writes go.set calls
---   end

local M                = {}

-- ─────────────────────────────────────────────────────────────
-- Tuning  (mirror Balatro values where possible)
-- ─────────────────────────────────────────────────────────────

-- Balatro: self.ambient_tilt = 0.2
-- Controls the RADIUS of the virtual-cursor orbit (0 = no tilt, 1 = extreme)
local AMBIENT_TILT     = 0.2

-- Balatro: tilt_factor = 0.3 (inside Card:draw)
-- Scales the orbit radius into an actual tilt amount
local TILT_FACTOR      = 0.3

-- Base angular speed (Balatro: 1.56 per second)
local BASE_SPEED       = 1.56

-- How much card ID randomises the speed (Balatro: (id/1.14212) % 1)
local SPEED_ID_DIVISOR = 1.14212

-- How much card ID randomises the starting phase (Balatro: id/1.35122)
local PHASE_ID_DIVISOR = 1.35122

-- Max tilt expressed as euler.z degrees and scale skew
-- Tune these to taste for your pixel art style
local MAX_ROT_DEG      = 0.1    --1.8    -- degrees of Z rotation at full tilt
local MAX_SCALE_SKEW   = 0.015  -- 0.012  -- scale.x squish at full tilt (perspective fake)

-- ─────────────────────────────────────────────────────────────
-- Init
-- ─────────────────────────────────────────────────────────────

---Initialise idle animation state.
---@param self     table    script self
---@param card_id  integer  unique card index (e.g. position in hand, 1-based)
function M.init(self, card_id)
    self.idle          = self.idle or {}

    -- Per-card unique speed and phase — same formula as Balatro
    self.idle.speed    = BASE_SPEED + (card_id / SPEED_ID_DIVISOR) % 1
    self.idle.phase    = card_id / PHASE_ID_DIVISOR

    -- Accumulated time (we track it ourselves so pausing is easy)
    self.idle.time     = 0

    -- Output values (written by update, read by apply)
    self.idle.tilt_x   = 0 -- normalised -1..1 horizontal cursor offset
    self.idle.tilt_y   = 0 -- normalised -1..1 vertical cursor offset
    self.idle.tilt_amt = 0 -- scalar "how much tilt right now" (0..1)

    -- Set false while card is hovered/dragged to suppress idle
    self.idle.active   = true
end

-- ─────────────────────────────────────────────────────────────
-- Update  –  call every frame
-- ─────────────────────────────────────────────────────────────

---Advance the idle animation.
---@param self  table   script self
---@param dt    number  delta time in seconds
function M.update(self, dt)
    -- if not self.idle or not self.idle.active then return end

    self.idle.time     = self.idle.time + dt

    -- Balatro:
    --   tilt_angle = G.TIMERS.REAL * speed + phase
    --   mx = (0.5 + 0.5 * ambient_tilt * cos(tilt_angle)) * card_w  ...
    --   my = (0.5 + 0.5 * ambient_tilt * sin(tilt_angle)) * card_h  ...
    --   amt = ambient_tilt * (0.5 + cos(tilt_angle)) * tilt_factor
    --
    -- We strip the pixel positions and keep only the normalised offsets
    -- (the 0.5 centre + 0.5*radius term), then remap to -1..1:
    --   raw_x = 0.5 + 0.5 * AMBIENT_TILT * cos(angle)   → range [0.4, 0.6]
    --   normalised = (raw_x - 0.5) / 0.5               → range [-0.2, 0.2]
    --   i.e. just:  AMBIENT_TILT * cos(angle)

    local angle        = self.idle.time * self.idle.speed + self.idle.phase

    self.idle.tilt_x   = AMBIENT_TILT * math.cos(angle)  -- -0.2 .. 0.2
    self.idle.tilt_y   = AMBIENT_TILT * math.sin(angle)  -- -0.2 .. 0.2
    self.idle.tilt_amt = AMBIENT_TILT * (0.5 + math.cos(angle)) * TILT_FACTOR
    --                                         ^ matches Balatro's amt formula exactly
end

-- ─────────────────────────────────────────────────────────────
-- Apply  –  writes the transform to the GO this frame
-- ─────────────────────────────────────────────────────────────

---Convert idle tilt state into go.set calls on the current GO.
---Call after update(), and after juice_up/flip transforms if combining.
---@param self       table   script self
---@param base_rot   number  base euler.z in degrees (default 0)
---@param base_sx    number  base scale.x (default 1)
---@param base_sy    number  base scale.y (default 1)
function M.apply(self, base_rot, base_sx, base_sy)
    if not self.idle then return end

    base_rot    = base_rot or 0
    base_sx     = base_sx or 1
    base_sy     = base_sy or 1

    local amt   = self.idle.tilt_amt -- 0 .. ~0.2

    -- Z rotation: tilt_x drives left/right lean
    -- Positive tilt_x (cursor right of centre) → card leans right
    local rot_z = base_rot + self.idle.tilt_x * MAX_ROT_DEG

    -- Perspective fake: when leaning right, left edge compresses slightly
    -- tilt_x > 0 → scale.x slightly less than 1 (foreshortening)
    local sx    = base_sx - math.abs(self.idle.tilt_x) * MAX_SCALE_SKEW

    -- Vertical bob: tilt_y drives a very subtle scale.y breathe
    local sy    = base_sy + self.idle.tilt_y * MAX_SCALE_SKEW * 0.5

    go.set(go.get_id(), "euler.z", rot_z)
    go.set(go.get_id(), "scale.x", sx)
    go.set(go.get_id(), "scale.y", sy)
end

-- ─────────────────────────────────────────────────────────────
-- Pause / resume (e.g. while hovering or dragging)
-- ─────────────────────────────────────────────────────────────

---Disable idle animation (e.g. on hover enter or drag start).
---The card snaps back to base transform — combine with your hover tween.
---@param self table
function M.pause(self)
    if self.idle then self.idle.active = false end
end

---Re-enable idle animation (e.g. on hover exit).
---@param self table
function M.resume(self)
    if self.idle then self.idle.active = true end
end

return M


--[[
═══════════════════════════════════════════════════════════════════
 FULL INTEGRATION EXAMPLE  –  card.script
 Combines idle_anim + card_anim (juice_up / flip) + hover
═══════════════════════════════════════════════════════════════════

local card_anim = require("modules.card_animations")
local idle_anim = require("modules.card_idle_anim")

local HOVER_LIFT     = 30     -- pixels
local HOVER_DURATION = 0.12   -- seconds

function init(self)
    -- card_id must be unique per card; pass index from deck/hand table
    local card_id = go.get("#", "card_id") or 1   -- or pass via message

    card_anim.init(self)
    idle_anim.init(self, card_id)

    self.base_pos_y  = go.get(go.get_id(), "position.y")
    self.hover_tween = nil
    self.is_hovering = false
end

function update(self, dt)
    card_anim.update(self, dt)   -- juice decay
    idle_anim.update(self, dt)   -- orbit advance

    -- Build base transform from juice
    local sx, sy, rz = card_anim.get_transform(self, 1, 1, 0)

    if self.is_hovering then
        -- While hovering: suppress idle, apply juice only
        go.set(go.get_id(), "euler.z",  rz)
        go.set(go.get_id(), "scale.x",  sx)
        go.set(go.get_id(), "scale.y",  sy)
    else
        -- Idle: layer juice on top of ambient tilt
        -- apply() adds idle offsets on top of juice base values
        idle_anim.apply(self, rz, sx, sy)
    end
end

function on_message(self, message_id, message, sender)

    -- ── hover enter ──────────────────────────────────────────
    if message_id == hash("hover_enter") then
        self.is_hovering = true
        idle_anim.pause(self)
        card_anim.juice_up(self, 0.05, 0.03)  -- tiny pop on enter

        if self.hover_tween then tweener.cancel(self.hover_tween) end
        local from_y = go.get(go.get_id(), "position.y")
        self.hover_tween = tweener.tween(
            tween.easing.outQuad, HOVER_DURATION,
            from_y, self.base_pos_y + HOVER_LIFT,
            function(v) go.set(go.get_id(), "position.y", v) end
        )

    -- ── hover exit ───────────────────────────────────────────
    elseif message_id == hash("hover_exit") then
        self.is_hovering = false
        idle_anim.resume(self)

        if self.hover_tween then tweener.cancel(self.hover_tween) end
        local from_y = go.get(go.get_id(), "position.y")
        self.hover_tween = tweener.tween(
            tween.easing.inQuad, HOVER_DURATION,
            from_y, self.base_pos_y,
            function(v) go.set(go.get_id(), "position.y", v) end
        )

    -- ── juice / flip ─────────────────────────────────────────
    elseif message_id == hash("juice_up") then
        card_anim.juice_up(self, message.scale, message.rot)

    elseif message_id == hash("flip") then
        card_anim.flip(self)
    end
end
]]
