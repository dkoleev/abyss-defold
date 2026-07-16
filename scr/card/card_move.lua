--- card_move.lua
--- Card transform system: spring easing (T→VT), juice, and idle orbit animation.
---
--- PROPERTY OWNERSHIP (no go.animate conflicts):
---   position  — always written by update() spring
---   euler.z   — written by update(): idle orbit + juice_r + VT.r composed together
---   scale     — written by update(): idle skew + juice_s + VT.sx composed together
---
--- go.animate is used ONLY for discard (position, fire-and-forget).
--- Everything else is per-frame go.set inside update().

local M                = {}

-- ─────────────────────────────────────────────────────────────────────────────
-- Spring constants
-- ─────────────────────────────────────────────────────────────────────────────

local EXP_XY           = 0.7
local EXP_ROT          = 0.75
local EXP_SCALE        = 0.65
local MAX_VEL          = 18.0
local SNAP_XY          = 0.5
local SNAP_ROT         = 0.002
local SNAP_SCALE       = 0.002

-- ─────────────────────────────────────────────────────────────────────────────
-- Idle orbit constants  (Balatro values)
-- ─────────────────────────────────────────────────────────────────────────────

-- local AMBIENT_TILT     = 0.2      -- orbit radius
-- local TILT_FACTOR      = 0.3      -- amt scale factor
-- local BASE_SPEED       = 1.56     -- rad/s
-- local SPEED_ID_DIVISOR = 1.14212
-- local PHASE_ID_DIVISOR = 1.35122
-- local MAX_ROT_DEG      = 3.0      -- euler.z at full lean
-- local MAX_SCALE_SKEW   = 0.025    -- scale compression at full lean

-- Tune values
-- Balatro: self.ambient_tilt = 0.2
-- Controls the RADIUS of the virtual-cursor orbit (0 = no tilt, 1 = extreme)
local AMBIENT_TILT     = 0.2 -- orbit radius
-- Balatro: tilt_factor = 0.3 (inside Card:draw)
-- Scales the orbit radius into an actual tilt amount
local TILT_FACTOR      = 0.3  -- amt scale factor
-- Base angular speed (Balatro: 1.56 per second)
local BASE_SPEED       = 1.56 -- rad/s
-- How much card ID randomises the speed (Balatro: (id/1.14212) % 1)
local SPEED_ID_DIVISOR = 1.14212
-- How much card ID randomises the starting phase (Balatro: id/1.35122)
local PHASE_ID_DIVISOR = 1.35122
-- Max tilt expressed as euler.z degrees and scale skew
-- Tune these to taste for your pixel art style
local MAX_ROT_DEG      = 3.0   -- degrees of Z rotation at full tilt
local MAX_SCALE_SKEW   = 0.025 -- scale.x squish at full tilt (perspective fake)

-- ─────────────────────────────────────────────────────────────────────────────
-- Cached hashes
-- ─────────────────────────────────────────────────────────────────────────────

local PROP_POS         = hash("position")
local PROP_ROT         = hash("euler.z")
local PROP_SCALE       = hash("scale")

-- ─────────────────────────────────────────────────────────────────────────────
-- Constructor
-- ─────────────────────────────────────────────────────────────────────────────

---@class CardMoveState
---@field T          table    target transform {x,y,z,r,sx}
---@field VT         table    visible transform, springs toward T
---@field vel        table    spring velocities {x,y,r,s}
---@field juice      table|nil
---@field idle       table|nil
---@field timer      number   accumulated dt
---@field stationary boolean
---@field go_url     url

---@param go_url  url | hash
---@param x       number
---@param y       number
---@param z       number
---@param rot_deg number
---@param card_id integer   unique 1-based index; drives per-card idle variation
---@return CardMoveState
function M.create(go_url, x, y, z, rot_deg, card_id)
    rot_deg = rot_deg or 0
    card_id = card_id or 1
    local state = {
        go_url     = go_url,
        T          = { x = x, y = y, z = z or 0, r = rot_deg, sx = 1.0 },
        VT         = { x = x, y = y, z = z or 0, r = rot_deg, sx = 1.0 },
        vel        = { x = 0, y = 0, r = 0, s = 0 },
        juice      = nil,
        timer      = 0,
        stationary = true,
        -- Idle orbit state
        idle       = {
            speed  = BASE_SPEED + (card_id / SPEED_ID_DIVISOR) % 1,
            phase  = card_id / PHASE_ID_DIVISOR,
            time   = 0,
            cx     = 0,
            cy     = 0,
            amt    = 0,
            active = true,
        },
    }
    go.set(go_url, PROP_POS, vmath.vector3(x, y, z or 0))
    go.set(go_url, PROP_ROT, rot_deg)
    go.set(go_url, PROP_SCALE, vmath.vector3(1, 1, 1))
    return state
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Update  —  call every frame
-- ─────────────────────────────────────────────────────────────────────────────

---@param state CardMoveState
---@param dt    number
function M.update(state, dt)
    state.timer = state.timer + dt
    local any_change = false

    -- ── XY spring ────────────────────────────────────────────────────────────
    local dx = state.T.x - state.VT.x
    local dy = state.T.y - state.VT.y
    if math.abs(dx) > SNAP_XY or math.abs(dy) > SNAP_XY
        or math.abs(state.vel.x) > 0.5 or math.abs(state.vel.y) > 0.5
    then
        state.vel.x = EXP_XY * state.vel.x + (1 - EXP_XY) * dx * 35 * dt
        state.vel.y = EXP_XY * state.vel.y + (1 - EXP_XY) * dy * 35 * dt
        local vmag2 = state.vel.x ^ 2 + state.vel.y ^ 2
        if vmag2 > MAX_VEL * MAX_VEL then
            local inv = MAX_VEL / math.sqrt(vmag2)
            state.vel.x = state.vel.x * inv
            state.vel.y = state.vel.y * inv
        end
        state.VT.x = state.VT.x + state.vel.x
        state.VT.y = state.VT.y + state.vel.y
        if math.abs(state.VT.x - state.T.x) < SNAP_XY and math.abs(state.vel.x) < 0.5 then
            state.VT.x = state.T.x; state.vel.x = 0
        end
        if math.abs(state.VT.y - state.T.y) < SNAP_XY and math.abs(state.vel.y) < 0.5 then
            state.VT.y = state.T.y; state.vel.y = 0
        end
        go.set(state.go_url, PROP_POS, vmath.vector3(state.VT.x, state.VT.y, state.VT.z))
        any_change = true
    end

    -- ── Rotation spring (VT.r tracks T.r; final write is composited below) ──
    local des_r = state.T.r
    if math.abs(des_r - state.VT.r) > SNAP_ROT or math.abs(state.vel.r) > SNAP_ROT then
        state.vel.r = EXP_ROT * state.vel.r + (1 - EXP_ROT) * (des_r - state.VT.r)
        state.VT.r  = state.VT.r + state.vel.r
        if math.abs(state.VT.r - state.T.r) < SNAP_ROT and math.abs(state.vel.r) < SNAP_ROT then
            state.VT.r = state.T.r; state.vel.r = 0
        end
        any_change = true
    end

    -- ── Scale spring (VT.sx tracks T.sx; final write is composited below) ───
    local des_s = state.T.sx
    if math.abs(des_s - state.VT.sx) > SNAP_SCALE or math.abs(state.vel.s) > SNAP_SCALE then
        state.vel.s = EXP_SCALE * state.vel.s + (1 - EXP_SCALE) * (des_s - state.VT.sx)
        state.VT.sx = state.VT.sx + state.vel.s
        if math.abs(state.VT.sx - des_s) < SNAP_SCALE and math.abs(state.vel.s) < SNAP_SCALE then
            state.VT.sx = des_s; state.vel.s = 0
        end
        any_change = true
    end

    -- ── Juice tick ───────────────────────────────────────────────────────────
    local juice_r, juice_s = 0, 0
    if state.juice then
        juice_r, juice_s = M._tick_juice(state, dt)
    end

    -- ── Idle orbit tick ──────────────────────────────────────────────────────
    local idle_rot_z, idle_sx, idle_sy = 0, state.VT.sx + juice_s, state.VT.sx + juice_s
    local idle = state.idle
    if idle and idle.active then
        idle.time   = idle.time + dt
        local angle = idle.time * idle.speed + idle.phase
        idle.cx     = 0.5 * AMBIENT_TILT * math.cos(angle)
        idle.cy     = 0.5 * AMBIENT_TILT * math.sin(angle)
        idle.amt    = AMBIENT_TILT * (0.5 + math.cos(angle)) * TILT_FACTOR

        -- Compose idle offsets on top of juice + VT base
        local norm  = 0.5 * AMBIENT_TILT -- normalise cx/cy to -1..1
        idle_rot_z  = idle.cx * MAX_ROT_DEG / norm
        idle_sx     = idle_sx - math.abs(idle.cx) * MAX_SCALE_SKEW / norm + idle.amt * 0.08
        idle_sy     = idle_sy + idle.cy * MAX_SCALE_SKEW * 0.6 / norm
        any_change  = true -- idle is always changing
    else
        idle_sy = idle_sx  -- uniform when idle is off
    end

    -- ── Final euler.z + scale write (single source of truth) ────────────────
    go.set(state.go_url, PROP_ROT, state.VT.r + juice_r + idle_rot_z)
    go.set(state.go_url, PROP_SCALE, vmath.vector3(idle_sx, idle_sy, 1))

    state.stationary = not any_change
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Juice
-- ─────────────────────────────────────────────────────────────────────────────

---Trigger a decaying sine-wave wobble (Balatro juice_up).
---@param state     CardMoveState
---@param amount    number
---@param rot_scale number|nil  degrees (default amount*15)
function M.juice(state, amount, rot_scale)
    state.juice = {
        amount    = amount,
        rot_scale = rot_scale or amount * 15,
        elapsed   = 0,
        duration  = 0.35,
    }
end

---@param state CardMoveState
---@param dt    number
---@return number juice_r, number juice_s
function M._tick_juice(state, dt)
    local j = state.juice
    j.elapsed = j.elapsed + dt
    if j.elapsed >= j.duration then
        state.juice = nil
        return 0, 0
    end
    local decay = math.max(0, 1 - j.elapsed / j.duration) ^ 2
    return j.rot_scale * math.sin(40 * j.elapsed) * decay,
        j.amount * math.sin(50 * j.elapsed) * decay
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Idle controls
-- ─────────────────────────────────────────────────────────────────────────────

---Pause idle orbit (hover, hold, select, discard).
---Outputs freeze at last value — no visual snap on resume.
---@param state CardMoveState
function M.idle_pause(state)
    if state.idle then state.idle.active = false end
end

---Resume idle orbit.
---@param state CardMoveState
function M.idle_resume(state)
    if state.idle then state.idle.active = true end
end

-- ─────────────────────────────────────────────────────────────────────────────
-- T setters
-- ─────────────────────────────────────────────────────────────────────────────

function M.move_to(state, x, y, z)
    state.T.x = x; state.T.y = y
    if z then state.T.z = z end
end

function M.rotate_to(state, deg) state.T.r = deg end

function M.scale_to(state, s) state.T.sx = s end

function M.hard_set(state, x, y, z)
    state.T.x = x; state.VT.x = x; state.vel.x = 0
    state.T.y = y; state.VT.y = y; state.vel.y = 0
    if z then
        state.T.z = z; state.VT.z = z
    end
    go.set(state.go_url, PROP_POS, vmath.vector3(x, y, state.VT.z))
end

function M.hard_set_rot(state, deg)
    state.T.r = deg; state.VT.r = deg; state.vel.r = 0
end

-- ─────────────────────────────────────────────────────────────────────────────
-- High-level transitions
-- ─────────────────────────────────────────────────────────────────────────────

function M.on_hover_enter(state, lift_y, scale_mul)
    M.idle_pause(state)
    state.T.y  = state.T.y + (lift_y or 22)
    state.T.sx = scale_mul or 1.08
    M.juice(state, 0.12, 3.0)
end

function M.on_hover_exit(state, base_y, base_sx)
    M.idle_resume(state)
    state.T.y  = base_y
    state.T.sx = base_sx or 1.0
end

function M.on_hold_start(state, lift_y)
    M.idle_pause(state)
    state.T.y  = state.T.y + (lift_y or 30)
    state.T.sx = 1.05
    M.juice(state, 0.08, 2.0)
end

function M.on_hold_end(state, base_y)
    M.idle_resume(state)
    state.T.y  = base_y
    state.T.sx = 1.08
end

function M.on_select(state, selected_y, rot_deg)
    M.idle_pause(state)
    state.T.y = selected_y
    state.T.r = rot_deg or 0
    M.juice(state, 0.30, 5.0)
end

function M.on_deselect(state, base_y, base_rot)
    M.idle_resume(state)
    state.T.y = base_y
    state.T.r = base_rot or 0
    M.juice(state, 0.10, 2.0)
end

function M.on_discard(state, discard_x, discard_y, end_rot_deg, on_done)
    M.idle_pause(state)
    state.T.x  = discard_x
    state.T.y  = discard_y
    state.T.r  = end_rot_deg or 45
    state.T.sx = 0.6
    go.cancel_animations(state.go_url, PROP_POS)
    go.animate(state.go_url, PROP_POS,
        go.PLAYBACK_ONCE_FORWARD,
        vmath.vector3(discard_x, discard_y, state.VT.z),
        go.EASING_OUTQUAD, 0.35, 0,
        function() if on_done then on_done() end end
    )
    state.VT.x = discard_x; state.VT.y = discard_y
end

function M.cancel_all_animations(state)
    go.cancel_animations(state.go_url, PROP_POS)
    go.cancel_animations(state.go_url, PROP_ROT)
    go.cancel_animations(state.go_url, PROP_SCALE)
end

return M
