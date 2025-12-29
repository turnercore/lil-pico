function init_game_state()
  game_state = {
    score = 0,
    level = 1,

    game_over = false,
    paused = false,
    pause_t = 0,
    bg_color = 0,
    toast = "",
    toast_t = 0,
    hit_flashes = {},

    projectiles = {},
    pickups = {},
    enemies = {},
    enemy_spawn_t = 30,
    spawn_min = nil,
    spawn_max = nil,
    spawn_enabled = true,

    shoot_repeat = false,
    shoot_cd = 0,
    shoot_btn_prev = false,
    shoot_combo_prev = false,

    current_wave = {},
    upgrade_choices = {},
    upgrade_index = 1,
    upgrade_confirm_ready = false,

    player = {
      cfg = {
        hp_max = 3,
        move_speed = 1,
        dodge_t = 6,
        dodge_cd = 60,
        dodge_invuln_t = 12,
        dodge_speed = 4,
        damage = 1,
        projectile_speed = 3,
        shoot_cd_max = 8,
        projectile_spread = 10
      },

      hp = 3,
      dead = false,
      position = { x = 0, y = 0 },
      dir = 1, -- 0=left,1=right,2=up,3=down
      moving = false,

      anim = {
        [0] = { 2, 2, 2, 1, 2 }, -- left
        [1] = { 1 }, -- right
        [2] = { 3 }, -- up
        [3] = { 4 } -- down
      },
      anim_i = 1,
      anim_tick = 0,

      idle_anim = {
        [0] = { 2 }, -- left idle
        [1] = { 1 }, -- right idle
        [2] = { 3 }, -- up idle
        [3] = { 4 } -- down
      },
      idle_anim_i = 1,
      idle_anim_tick = 0,

      prev_dir = 1,
      prev_moving = false,

      dodge_t = 0,
      dodge_cd = 0,
      dodge_vx = 0,
      dodge_vy = 0,
      invuln_t = 0,
      hit_flash = nil
    }
  }

  game_state.player.hp = game_state.player.cfg.hp_max or 3
  set_level(game_state.level, true)
  init_upgrades()
end

-- temporary gameplay pause (eg hit-stop)
function pause_game(frames)
  frames = frames or 0
  if frames <= 0 then
    return
  end
  game_state.pause_t = max(game_state.pause_t or 0, frames)
  game_state.paused = true
end

function update_pause()
  local t = game_state.pause_t or 0
  if t > 0 then
    t -= 1
    game_state.pause_t = t
    if t <= 0 then
      game_state.pause_t = 0
      game_state.paused = false
    end
  end
end

-- app state machine
GS_MENU = 0
GS_GAMEPLAY = 1
GS_UPGRADES = 2
GS_GAME_OVER = 3

function init_app_state()
  app_state = GS_MENU
  app_prev_state = nil
end

function set_app_state(next_state)
  if app_state == next_state then
    return
  end

  local prev = app_state
  app_prev_state = prev

  if next_state == GS_UPGRADES and prev ~= GS_GAMEPLAY then
    return
  end

  app_state = next_state

  if next_state == GS_MENU then
    -- keep current music for now
    game_state.game_over = true
  elseif next_state == GS_GAMEPLAY then
    game_state.game_over = false
    game_state.paused = false
    game_state.pause_t = 0

    if prev == GS_MENU then
      init_game_state()
      game_state.toast = ""
      game_state.toast_t = 0
    elseif prev == GS_GAME_OVER then
      reset_game_state()
    end
  elseif next_state == GS_UPGRADES then
    game_state.game_over = true
    game_state.upgrade_confirm_ready = false
  elseif next_state == GS_GAME_OVER then
    game_state.game_over = true
    game_state.player.dead = true
    game_state.enemies = {}
    game_state.projectiles = {}
    game_state.pickups = {}
    game_state.toast = "game over"
    game_state.toast_t = 9999
    music(-1)
  end
end

function update_app_state()
  if app_state == GS_MENU then
    if btnp(4) or btnp(5) then
      set_app_state(GS_GAMEPLAY)
    end
    return
  end

  if app_state == GS_UPGRADES then
    update_upgrade_input()
    return
  end

  if app_state == GS_GAME_OVER then
    -- restart on holding both action buttons
    if btn(4) and btn(5) then
      set_app_state(GS_GAMEPLAY)
    else
      update_toast()
    end
    return
  end

  -- gameplay
  if game_state.paused then
    update_pause()
    return
  end
  update_hit_flashes()
  update_player_position()
  update_player_animation()
  update_player_actions()
  update_projectiles()
  update_enemies()
  if app_state ~= GS_GAMEPLAY then
    return
  end
  update_pickups()
  update_toast()

  if check_level_progression() then
    set_app_state(GS_UPGRADES)
  end
end

function draw_app_state()
  cls(game_state.bg_color or 0)

  if app_state == GS_MENU then
    ui_draw_main_menu()
    return
  end

  if app_state == GS_UPGRADES then
    -- show the current scene under the upgrades overlay
    if not game_state.player.dead then
      draw_player()
    end
    draw_projectiles()
    draw_enemies()
    draw_pickups()
    draw_ui()
    ui_draw_upgrades()
    return
  end

  -- gameplay/game over share base scene rendering
  if not game_state.player.dead then
    draw_player()
  end
  draw_projectiles()
  draw_enemies()
  draw_pickups()
  draw_ui()

  if app_state == GS_GAME_OVER then
    ui_draw_game_over()
  end
end

function reset_game_state()
  init_game_state()
  game_state.toast = "game restarted"
  game_state.toast_t = 30
end

function set_game_over()
  if app_state == GS_GAME_OVER then
    return
  end
  set_app_state(GS_GAME_OVER)
end

function set_level(level_num, silent)
  game_state.level = level_num
  if not silent then
    game_state.toast = "level " .. game_state.level
    game_state.toast_t = 30
  end

  local wave_def = wave_defs and wave_defs[level_num]
  if wave_def then
    local wave = wave_def.wave or wave_def
    game_state.current_wave = wave
    game_state.spawn_min = wave_def.spawn_min
    game_state.spawn_max = wave_def.spawn_max
    if wave_def.bg_color ~= nil then
      game_state.bg_color = wave_def.bg_color
    elseif wave_def.wave_bg_color ~= nil then
      game_state.bg_color = wave_def.wave_bg_color
    end
    game_state.enemy_spawn_t = 0
    if wave_def.all_at_once and (wave_def.all_at_once_amount or 0) > 0 then
      game_state.spawn_enabled = false
      spawn_enemy_ring(wave_def.all_at_once_amount)
    else
      game_state.spawn_enabled = true
    end
  else
    game_state.spawn_min = nil
    game_state.spawn_max = nil
    game_state.spawn_enabled = true
  end

  return true
end

function init_upgrades()
  upgrade_defs = {
    { id = "hp", title = "+hp", desc = "hp max +1, heal 1", apply = apply_upgrade_hp, sfx = SFX_UPGRADE_PICK },
    { id = "speed", title = "+speed", desc = "move a bit faster", apply = apply_upgrade_speed, sfx = SFX_UPGRADE_PICK },
    { id = "damage", title = "+damage", desc = "projectiles +1 dmg", apply = apply_upgrade_damage, sfx = SFX_UPGRADE_PICK },
    { id = "proj_speed", title = "+proj speed", desc = "shots fly faster", apply = apply_upgrade_proj_speed, sfx = SFX_UPGRADE_PICK },
    { id = "fire_rate", title = "+fire rate", desc = "shoot cooldown down", apply = apply_upgrade_fire_rate, sfx = SFX_UPGRADE_PICK }
  }
end

function roll_upgrades()
  game_state.upgrade_choices = {}
  game_state.upgrade_index = 1

  local used = {}
  local n = min(3, #upgrade_defs)
  for i = 1, n do
    local pick = nil
    local tries = 0
    while not pick and tries < 20 do
      local idx = flr(rnd(#upgrade_defs)) + 1
      local def = upgrade_defs[idx]
      if def and not used[def.id] then
        used[def.id] = true
        pick = def
      end
      tries += 1
    end
    if pick then
      add(game_state.upgrade_choices, pick)
    end
  end
end

function update_upgrade_input()
  if #game_state.upgrade_choices == 0 then
    roll_upgrades()
  end

  if not game_state.upgrade_confirm_ready then
    if not btn(4) and not btn(5) then
      game_state.upgrade_confirm_ready = true
    else
      return
    end
  end

  if btnp(2) then
    game_state.upgrade_index -= 1
    if game_state.upgrade_index < 1 then
      game_state.upgrade_index = #game_state.upgrade_choices
    end
    sfx(SFX_SHOOT)
  elseif btnp(3) then
    game_state.upgrade_index += 1
    if game_state.upgrade_index > #game_state.upgrade_choices then
      game_state.upgrade_index = 1
    end
    sfx(SFX_SHOOT)
  elseif btnp(5) then
    local pick = game_state.upgrade_choices[game_state.upgrade_index]
    if pick then
      if pick.apply then
        pick.apply()
      end
      local sfx_id = pick.sfx
      if sfx_id == nil then
        sfx_id = SFX_UPGRADE_PICK
      end
      if sfx_id ~= nil then
        sfx(sfx_id)
      end
    end
    game_state.upgrade_choices = {}
    game_state.upgrade_index = 1
    set_app_state(GS_GAMEPLAY)
  end
end

function apply_upgrade_hp()
  local cfg = game_state.player.cfg
  cfg.hp_max = (cfg.hp_max or 3) + 1
  game_state.player.hp = min(cfg.hp_max, (game_state.player.hp or 0) + 1)
end

function apply_upgrade_speed()
  local cfg = game_state.player.cfg
  cfg.move_speed = (cfg.move_speed or 1) + 0.2
end

function apply_upgrade_damage()
  local cfg = game_state.player.cfg
  cfg.damage = (cfg.damage or 1) + 1
end

function apply_upgrade_proj_speed()
  local cfg = game_state.player.cfg
  cfg.projectile_speed = (cfg.projectile_speed or 3) + 0.5
end

function apply_upgrade_fire_rate()
  local cfg = game_state.player.cfg
  cfg.shoot_cd_max = max(2, (cfg.shoot_cd_max or 8) - 1)
end
