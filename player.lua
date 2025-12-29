-- Player Actions and Movement
function update_player_actions()
  local shoot_held = btn(4)
  local dodge_pressed = btnp(5)
  local combo = shoot_held and btn(5)

  if combo and not game_state.shoot_combo_prev then
    game_state.shoot_repeat = not game_state.shoot_repeat
    game_state.toast = game_state.shoot_repeat and "shoot: repeat" or "shoot: single"
    game_state.toast_t = 30
  end
  game_state.shoot_combo_prev = combo

  if game_state.shoot_cd > 0 then
    game_state.shoot_cd -= 1
  end

  local can_act = not game_state.game_over and not game_state.player.dead
  if can_act and not combo then
    local shoot_wanted
    if game_state.shoot_repeat then
      shoot_wanted = shoot_held
    else
      shoot_wanted = shoot_held and not game_state.shoot_btn_prev
    end

    if shoot_wanted and game_state.shoot_cd <= 0 then
      player_shoot()
      game_state.shoot_cd = (game_state.player.cfg and game_state.player.cfg.shoot_cd_max) or 8
    end

    if dodge_pressed and game_state.player.dodge_cd <= 0 then
      player_dodge()
    end
  end

  game_state.shoot_btn_prev = shoot_held
end

function player_shoot()
  -- Logic for player shooting action
  if game_state.game_over or game_state.player.dead then
    return
  end

  local x = game_state.player.position.x + 4
  local y = game_state.player.position.y + 4
  local cfg = game_state.player.cfg or {}
  local speed = cfg.projectile_speed or 2

  local vx, vy = 0, 0
  if game_state.player.dir == 0 then
    vx = -speed
  elseif game_state.player.dir == 1 then
    vx = speed
  elseif game_state.player.dir == 2 then
    vy = -speed
  elseif game_state.player.dir == 3 then
    vy = speed
  end

  -- "wild shot" when repeat is enabled: add a bit of random spread to velocity
  if game_state.shoot_repeat then
    local spread = (cfg.projectile_spread or 0) * 0.1
    vx += rnd(spread * 2) - spread
    vy += rnd(spread * 2) - spread

    local d = sqrt(vx * vx + vy * vy)
    if d > 0 then
      vx = (vx / d) * speed
      vy = (vy / d) * speed
    end
  end

  spawn_projectile(x, y, game_state.player.dir, vx, vy)
end

function player_dodge()
  if game_state.game_over or game_state.player.dead then
    return
  end

  if game_state.player.dodge_cd > 0 or game_state.player.dodge_t > 0 then
    return
  end

  local cfg = game_state.player.cfg or {}
  local ix, iy = 0, 0
  if btn(0) then ix -= 1 end
  -- left
  if btn(1) then ix += 1 end
  -- right
  if btn(2) then iy -= 1 end
  -- up
  if btn(3) then iy += 1 end
  -- down

  if ix == 0 and iy == 0 then
    local dir = game_state.player.dir
    if dir == 0 then
      ix = -1
    elseif dir == 1 then
      ix = 1
    elseif dir == 2 then
      iy = -1
    elseif dir == 3 then
      iy = 1
    end
  else
    if ix < 0 then
      game_state.player.dir = 0
    elseif ix > 0 then
      game_state.player.dir = 1
    elseif iy < 0 then
      game_state.player.dir = 2
    elseif iy > 0 then
      game_state.player.dir = 3
    end
  end

  local speed = cfg.dodge_speed or 3
  local vx, vy = 0, 0
  if ix ~= 0 and iy ~= 0 then
    local s = speed * 0.70710678
    vx = ix * s
    vy = iy * s
  else
    vx = ix * speed
    vy = iy * speed
  end

  game_state.player.dodge_vx = vx
  game_state.player.dodge_vy = vy
  game_state.player.dodge_t = cfg.dodge_t or 10
  game_state.player.invuln_t = cfg.dodge_invuln_t or 15
  game_state.player.dodge_cd = cfg.dodge_cd or 30
end

function player_hit(dmg, hit_invuln_t)
  if game_state.player.dead or game_state.player.invuln_t > 0 then
    return false
  end

  dmg = dmg or 1
  game_state.player.hp -= dmg
  game_state.player.hit_flash = add_hit_flash(8, 5, 8)
  game_state.toast = "ouch! hp: " .. game_state.player.hp
  game_state.toast_t = 30
  pause_game(6)
  game_state.player.invuln_t = hit_invuln_t or 20

  if game_state.player.hp <= 0 then
    set_game_over()
  end

  return true
end

function update_player_position()
  -- Example logic to update player position
  local ix, iy = 0, 0
  local prev_dir = game_state.player.dir
  local was_moving = game_state.player.moving
  game_state.player.prev_dir = prev_dir
  game_state.player.prev_moving = was_moving

  if game_state.player.dodge_cd > 0 then
    game_state.player.dodge_cd -= 1
  end
  if game_state.player.invuln_t > 0 then
    game_state.player.invuln_t -= 1
  end

  if game_state.player.dodge_t > 0 then
    game_state.player.dodge_t -= 1
    local dx = game_state.player.dodge_vx
    local dy = game_state.player.dodge_vy
    game_state.player.moving = true
    game_state.player.position.x += dx
    game_state.player.position.y += dy
    game_state.player.position.x, game_state.player.position.y = wrap_xy(game_state.player.position.x, game_state.player.position.y, 8, 8)
    return
  end

  if btn(0) then ix -= 1 end
  -- left
  if btn(1) then ix += 1 end
  -- right
  if btn(2) then iy -= 1 end
  -- up
  if btn(3) then iy += 1 end
  -- down

  local moved = (ix ~= 0) or (iy ~= 0)
  local speed = 1

  -- prevent diagonal movement being faster than cardinal movement
  local dx, dy = ix, iy
  if dx ~= 0 and dy ~= 0 then
    local s = speed * 0.70710678
    dx = dx * s
    dy = dy * s
  else
    dx = dx * speed
    dy = dy * speed
  end

  game_state.player.moving = moved

  if moved then
    if ix < 0 then
      game_state.player.dir = 0
    elseif ix > 0 then
      game_state.player.dir = 1
    elseif iy < 0 then
      game_state.player.dir = 2
    elseif iy > 0 then
      game_state.player.dir = 3
    end
  end

  game_state.player.position.x += dx
  game_state.player.position.y += dy
  game_state.player.position.x, game_state.player.position.y = wrap_xy(game_state.player.position.x, game_state.player.position.y, 8, 8)
end

-- Projectile Functions
function spawn_projectile(x, y, dir, vx, vy)
  local speed = (game_state.player.cfg and game_state.player.cfg.projectile_speed) or 2
  if vx == nil or vy == nil then
    vx, vy = 0, 0
    if dir == 0 then
      vx = -speed
    elseif dir == 1 then
      vx = speed
    elseif dir == 2 then
      vy = -speed
    elseif dir == 3 then
      vy = speed
    end
  end

  local p = { x = x, y = y, vx = vx, vy = vy, r = 1 }
  add(game_state.projectiles, p)
end

function update_projectiles()
  if game_state.game_over then
    return
  end

  for i = #game_state.projectiles, 1, -1 do
    local p = game_state.projectiles[i]
    local ox = p.x
    local oy = p.y
    p.x += p.vx
    p.y += p.vy

    local hit = false
    for j = #game_state.enemies, 1, -1 do
      local e = game_state.enemies[j]
      local r = p.r or 1
      local rx = e.x - r
      local ry = e.y - r
      local rw = e.w + r * 2
      local rh = e.h + r * 2

      -- step along the movement to avoid tunneling through enemies at higher speeds
      local steps = flr(max(abs(p.vx), abs(p.vy)) + 0.999999)
      if steps < 1 then steps = 1 end
      for s = 1, steps do
        local t = s / steps
        local sx = ox + (p.vx * t)
        local sy = oy + (p.vy * t)
        if point_in_rect(sx, sy, rx, ry, rw, rh) then
          if enemy_take_damage(e, 1, j) then
            deli(game_state.projectiles, i)
            hit = true
          end
          break
        end
      end
      if hit then break end
    end
    if not hit then
      if is_offscreen_xy(p.x, p.y, p.r * 2, p.r * 2, 2) then
        deli(game_state.projectiles, i)
      end
    end
  end
end

function draw_projectiles()
  for p in all(game_state.projectiles) do
    local x = flr(p.x + 0.5)
    local y = flr(p.y + 0.5)
    local should_flip_x = p.vx < 0
    local should_flip_y = p.vy > 0
    local is_facing_updown = abs(p.vy) > abs(p.vx)
    if is_facing_updown then
      local use_spr_id = 15
      spr(use_spr_id, x - 1, y - 1, 1, 1, should_flip_x, should_flip_y)
    else
      local use_spr_id = 14
      spr(use_spr_id, x - 1, y - 1, 1, 1, should_flip_x, should_flip_y)
    end
  end
end

-- Player Animations and Drawing
function draw_player()
  if game_state.player.dead then
    return
  end

  local frames, i
  if game_state.player.moving then
    frames = game_state.player.anim[game_state.player.dir]
    i = game_state.player.anim_i
  else
    frames = game_state.player.idle_anim[game_state.player.dir]
    i = game_state.player.idle_anim_i
  end

  local sprite_id = frames and frames[i] or 1
  local px = flr(game_state.player.position.x + 0.5)
  local py = flr(game_state.player.position.y + 0.5)
  draw_sprite_hit_effect(sprite_id, px, py, game_state.player.hit_flash)
end

function update_player_animation()
  local prev_dir = game_state.player.prev_dir or game_state.player.dir
  local was_moving = game_state.player.prev_moving or false

  if game_state.player.moving then
    game_state.player.idle_anim_tick = 0
    game_state.player.idle_anim_i = 1

    if not was_moving then
      game_state.player.anim_tick = 0
      game_state.player.anim_i = 1
    end

    if game_state.player.dir ~= prev_dir then
      game_state.player.anim_tick = 0
      game_state.player.anim_i = 1
    end

    game_state.player.anim_tick += 1
    if (game_state.player.anim_tick % 8) == 0 then
      local frames = game_state.player.anim[game_state.player.dir]
      local n = frames and #frames or 0
      if n > 0 then
        game_state.player.anim_i = (game_state.player.anim_i % n) + 1
      else
        game_state.player.anim_i = 1
      end
    end
  else
    game_state.player.idle_anim_tick = 0
    game_state.player.idle_anim_i = 1

    local frames = game_state.player.idle_anim[game_state.player.dir]
    local n = frames and #frames or 0
    if n > 0 then
      game_state.player.idle_anim_tick += 1
      if (game_state.player.idle_anim_tick % 16) == 0 then
        game_state.player.idle_anim_i = (game_state.player.idle_anim_i % n) + 1
      end
    else
      game_state.player.idle_anim_tick = 0
      game_state.player.idle_anim_i = 1
    end
  end
end
