function init_game_state()
  game_state = {
    score = 0,
    level = 1,

    game_over = false,
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

function reset_game_state()
  init_game_state()
  game_state.toast = "game restarted"
  game_state.toast_t = 30
end
