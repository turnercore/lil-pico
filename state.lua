function init_game_state()
  game_state = {
    score = 0,
    level = 1,

    game_over = false,
    paused = false,
    pause_t = 0,
    toast = "",
    toast_t = 0,

    projectiles = {},
    pickups = {},
    enemies = {},
    enemy_spawn_t = 30,

    shoot_repeat = false,
    shoot_cd = 0,
    shoot_btn_prev = false,
    shoot_combo_prev = false,

    player = {
      cfg = {
        hp_max = 3,
        dodge_t = 6,
        dodge_cd = 60,
        dodge_invuln_t = 12,
        dodge_speed = 4,
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
      invuln_t = 0
    }
  }

  game_state.player.hp = game_state.player.cfg.hp_max or 3
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
      start_bgm(0)
    elseif prev == GS_GAME_OVER then
      reset_game_state()
      start_bgm(0)
    end
  elseif next_state == GS_UPGRADES then
    game_state.game_over = true
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
    -- placeholder upgrades screen: back/resume
    if btnp(4) or btnp(5) then
      set_app_state(GS_GAMEPLAY)
    end
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
  cls()

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