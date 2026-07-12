--- card_animations.lua
--- Defold port of Balatro's juice_up and flip card animations.
---
--- Usage (from your card script):
---   local card_anim = require("modules.card_animations")
---
---   -- in init(self):
---   card_anim.init(self)
---
---   -- in update(self, dt):
---   card_anim.update(self, dt)
---
---   -- trigger anywhere:
---   card_anim.juice_up(self, 0.11, 0.16)   -- scale_amount, rot_amount
---   card_anim.flip(self)                    -- toggles front/back

local tweener              = require("tweener.tweener")
local visual_settings      = require("scr.settings.visual_settings")

local M                    = {}

-- ─────────────────────────────────────────────
-- Constants
-- ─────────────────────────────────────────────

local JUICE_SCALE_DECAY    = 8.0  -- how fast the scale bump springs back
local JUICE_ROT_DECAY      = 6.0  -- how fast the rotation springs back
local FLIP_SPEED           = 6.0  -- X-scale pinch speed (units/sec)

-- ─────────────────────────────────────────────
-- Init  –  call once inside script init(self)
-- ─────────────────────────────────────────────

---Initialise animation state on a card script self.
---@param self table  script self
function M.init(self)
    -- juice_up state
    self.anim                   = self.anim or {}
    self.anim.juice_scale       = 0 -- extra scale currently applied
    self.anim.juice_rot         = 0 -- extra Z-rotation currently applied (radians)

    -- flip state
    self.anim.flip_state        = "idle" -- "idle" | "folding" | "unfolding"
    self.anim.flip_scale_x      = 1      -- goes 1 → 0 → 1 during a flip
    -- "front" / "back"  – set this to whatever your initial facing is
    self.anim.facing            = self.anim.facing or "front"
    -- called when the facing actually switches (mid-flip, at scale_x == 0)
    -- override per card:  self.anim.on_facing_changed = function(facing) ... end
    self.anim.on_facing_changed = self.anim.on_facing_changed or nil
end

-- ─────────────────────────────────────────────
-- hovering  –  call to trigger the pop animation
-- ─────────────────────────────────────────────

function M.on_hover_enter(self)
    go.cancel_animations(self.go_id, "position.y")
    go.cancel_animations(self.go_id, "scale")

    local start_y = go.get_position(self.go_id).y

    go.animate(
        self.go_id, "position.y",
        go.PLAYBACK_ONCE_FORWARD,
        start_y + visual_settings.card.hover_lift,
        go.EASING_OUTQUAD,
        visual_settings.card.hover_lift_duration
    )

    go.animate(
        self.go_id, "scale",
        go.PLAYBACK_ONCE_FORWARD,
        visual_settings.card.hover_scale,
        go.EASING_OUTBACK, -- overshoot feels more "juicy"
        visual_settings.card.hover_scale_duration
    )
end

function M.on_hover_exit(self)
    go.cancel_animations(self.go_id, "position.y")
    go.cancel_animations(self.go_id, "scale")

    local start_y = go.get_position(self.go_id).y

    go.animate(
        self.go_id, "position.y",
        go.PLAYBACK_ONCE_FORWARD,
        start_y - visual_settings.card.hover_lift,
        go.EASING_OUTQUAD,
        visual_settings.card.hover_lift_duration
    )

    go.animate(
        self.go_id, "scale",
        go.PLAYBACK_ONCE_FORWARD,
        visual_settings.card.base_scale,
        go.EASING_OUTQUAD,
        visual_settings.card.hover_scale_duration
    )
end

-- ─────────────────────────────────────────────
-- juice_up  –  call to trigger the pop animation
-- ─────────────────────────────────────────────

---Trigger a quick scale-pop + random rotation jolt (Balatro juice_up).
---@param self        table   script self (must have called M.init first)
---@param scale_amt   number  base scale bump (Balatro default 0.11)
---@param rot_amt     number  base rotation bump in radians (Balatro default 0.16)
function M.juice_up(self, scale_amt, rot_amt)
    scale_amt             = scale_amt or 0.11
    rot_amt               = rot_amt or 0.16

    -- Balatro multiplies incoming values the same way:
    --   scale = scale * 0.4
    --   rot   = 0.4 * random_sign * rot_amount
    local scale           = scale_amt * 0.4
    local sign            = (math.random() > 0.5) and 1 or -1
    local rot             = 0.4 * sign * rot_amt

    -- Accumulate on top of whatever is already playing
    self.anim.juice_scale = self.anim.juice_scale + scale
    self.anim.juice_rot   = self.anim.juice_rot + rot
end

-- ─────────────────────────────────────────────
-- flip  –  toggles front / back with a pinch
-- ─────────────────────────────────────────────

---Start a flip to the opposite facing.
---@param self table  script self
function M.flip(self)
    if self.anim.flip_state ~= "idle" then return end -- already flipping
    self.anim.flip_state = "folding"
end

-- ─────────────────────────────────────────────
-- update  –  call every frame inside script update(self, dt)
-- ─────────────────────────────────────────────

---Drive all animations.  Apply the resulting transform yourself (see example below).
---@param self  table   script self
---@param dt    number  delta time in seconds
function M.update(self, dt)
    M._update_juice(self, dt)
    M._update_flip(self, dt)
end

-- ─────────────────────────────────────────────
-- Internal helpers
-- ─────────────────────────────────────────────

function M._update_juice(self, dt)
    if self.anim.juice_scale == 0 and self.anim.juice_rot == 0 then return end

    -- Exponential decay back toward zero (spring-like, framerate-independent)
    local scale_decay     = math.exp(-JUICE_SCALE_DECAY * dt)
    local rot_decay       = math.exp(-JUICE_ROT_DECAY * dt)

    self.anim.juice_scale = self.anim.juice_scale * scale_decay
    self.anim.juice_rot   = self.anim.juice_rot * rot_decay

    -- Snap to zero when close enough to avoid infinite tail
    if math.abs(self.anim.juice_scale) < 0.001 then self.anim.juice_scale = 0 end
    if math.abs(self.anim.juice_rot) < 0.0005 then self.anim.juice_rot = 0 end
end

function M._update_flip(self, dt)
    if self.anim.flip_state == "idle" then return end

    local speed = FLIP_SPEED * dt

    if self.anim.flip_state == "folding" then
        -- Shrink X toward 0
        self.anim.flip_scale_x = self.anim.flip_scale_x - speed
        if self.anim.flip_scale_x <= 0 then
            self.anim.flip_scale_x = 0

            -- Mid-flip: switch the visible face
            self.anim.facing = (self.anim.facing == "front") and "back" or "front"
            if self.anim.on_facing_changed then
                self.anim.on_facing_changed(self.anim.facing)
            end

            self.anim.flip_state = "unfolding"
        end
    elseif self.anim.flip_state == "unfolding" then
        -- Grow X back to 1
        self.anim.flip_scale_x = self.anim.flip_scale_x + speed
        if self.anim.flip_scale_x >= 1 then
            self.anim.flip_scale_x = 1
            self.anim.flip_state   = "idle"
        end
    end
end

-- ─────────────────────────────────────────────
-- Convenience: build the final go.set values
-- ─────────────────────────────────────────────

---Return the final scale and rotation to apply this frame.
---Combine with your card's base scale and rotation.
---@param self       table   script self
---@param base_sx    number  card base X scale (e.g. 1.0)
---@param base_sy    number  card base Y scale (e.g. 1.0)
---@param base_rot   number  card base Z rotation in radians (e.g. 0)
---@return number sx, number sy, number rot_z
function M.get_transform(self, base_sx, base_sy, base_rot)
    base_sx     = base_sx or 1
    base_sy     = base_sy or 1
    base_rot    = base_rot or 0

    local juice = self.anim.juice_scale
    local sx    = (base_sx + juice) * self.anim.flip_scale_x
    local sy    = base_sy + juice
    local rz    = base_rot + self.anim.juice_rot

    return sx, sy, rz
end

return M


--[[
═══════════════════════════════════════════════════════
 USAGE EXAMPLE  –  card.script
═══════════════════════════════════════════════════════

local card_anim = require("modules.card_animations")

-- Nodes: assume "front" and "back" are children of the card GO
local FRONT_URL = "front#sprite"
local BACK_URL  = "back#sprite"

function init(self)
    card_anim.init(self)

    -- Hide back sprite at start (card shows front)
    go.set(BACK_URL, "tint.w", 0)

    -- Wire the facing-change callback to swap visible sprites
    self.anim.on_facing_changed = function(facing)
        go.set(FRONT_URL, "tint.w", facing == "front" and 1 or 0)
        go.set(BACK_URL,  "tint.w", facing == "back"  and 1 or 0)
    end

    self.base_rot = 0   -- radians; change for tilted/hand cards
end

function update(self, dt)
    card_anim.update(self, dt)

    local sx, sy, rz = card_anim.get_transform(self, 1, 1, self.base_rot)

    go.set(go.get_id(), "scale.x", sx)
    go.set(go.get_id(), "scale.y", sy)
    -- Defold rotation is a quaternion; for 2D Z-only rotation:
    go.set(go.get_id(), "euler.z", math.deg(rz))
end

function on_message(self, message_id, message, sender)
    if message_id == hash("juice_up") then
        -- optional custom scale/rot from message data
        card_anim.juice_up(self, message.scale, message.rot)

    elseif message_id == hash("flip") then
        card_anim.flip(self)
    end
end

-- Call from anywhere in the same script:
--   card_anim.juice_up(self)           -- default pop
--   card_anim.juice_up(self, 0.2, 0.3) -- bigger pop
--   card_anim.flip(self)               -- toggle face
]]
