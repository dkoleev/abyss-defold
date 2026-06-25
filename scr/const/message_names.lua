-- engine_messages.lua
-- Pre-hashed built-in Defold message IDs.
-- Import: local EM = require("shared.engine_messages")

local M                       = {}

-- ─── Lifecycle ────────────────────────────────────────────────────────────────
M.init                        = hash("init")
M.final                       = hash("final")
M.load                        = hash("load")
M.unload                      = hash("unload")
M.proxy_loaded                = hash("proxy_loaded")
M.proxy_unloaded              = hash("proxy_unloaded")
M.enable                      = hash("enable")
M.disable                     = hash("disable")

-- ─── Input ────────────────────────────────────────────────────────────────────
M.acquire_input_focus         = hash("acquire_input_focus")
M.release_input_focus         = hash("release_input_focus")

-- ─── Physics ──────────────────────────────────────────────────────────────────
M.contact_point_response      = hash("contact_point_response")
M.trigger_response            = hash("trigger_response")
M.ray_cast_response           = hash("ray_cast_response")
M.ray_cast_missed             = hash("ray_cast_missed")
M.apply_force                 = hash("apply_force")
M.collision_response          = hash("collision_response")

-- ─── Rendering ────────────────────────────────────────────────────────────────
M.draw_line                   = hash("draw_line")
M.draw_text                   = hash("draw_text")
M.window_resized              = hash("window_resized")
M.window_focus_lost           = hash("window_focus_lost")
M.set_view_projection         = hash("set_view_projection")

-- ─── Game Object ──────────────────────────────────────────────────────────────
M.set_parent                  = hash("set_parent")
M.unset_parent                = hash("unset_parent")

-- ─── Sprite ──────────────────────────────────────────────────────────────
M.animation_done              = hash("animation_done")

-- ─── GUI ──────────────────────────────────────────────────────────────────────
M.layout_changed              = hash("layout_changed")

-- ─── Sound ────────────────────────────────────────────────────────────────────
M.sound_done                  = hash("sound_done")
M.set_listener                = hash("set_listener")

-- ─── Spine / Model ────────────────────────────────────────────────────────────
M.spine_animation_done        = hash("spine_animation_done")
M.spine_event                 = hash("spine_event")
M.model_animation_done        = hash("model_animation_done")

-- ─── Particle FX ──────────────────────────────────────────────────────────────
M.particle_fx_stopped         = hash("particle_fx_stopped")

-- ─── Script ───────────────────────────────────────────────────────────────────
M.acquire_camera_focus        = hash("acquire_camera_focus")
M.release_camera_focus        = hash("release_camera_focus")

-- ─── Game Custom ──────────────────────────────────────────────────────────────
M.delete                      = hash("delete")
M.take_damage                 = hash("take_damage")
M.dead                        = hash("dead")
M.enter_fight                 = hash("enter_fight")
M.exit_fight                  = hash("exit_fight")
M.attack                      = hash("attack")
M.damned_attack_finished      = hash("damned_attack_finished")
M.damned_attack_apply         = hash("damned_attack_apply")
M.apply_effect                = hash("apply_effect")
M.player_damage_changed       = hash("player_damage_changed")
M.player_damage_mult_changed  = hash("player_damage_mult_changed")
M.player_final_damage_changed = hash("player_final_damage_mult_changed")

-- ─── Slots ────────────────────────────────────────────────────────────────────

M.start_spin                  = hash("start_spin")
M.stop_reel                   = hash("stop_spin")
M.reel_stopped                = hash("reel_stopped")

return M
