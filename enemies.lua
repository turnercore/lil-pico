-- sound effect constants
SFX_ENEMY_DEATH = 57

-- enemy config: stats, sprites, drops
enemy_types = {
  basic = {
    spr = { 16, 17 },
    w = 8,
    h = 8,
    spd = 0.5,
    hp = 1,
    score = 5,
    sfx_death = SFX_ENEMY_DEATH,
    base_col = 11,
    mod_col = nil,
    drop_table = {
      { min = 90, max = 100, key = "hp" }
    },
    anim_rate = 8,
    dmg = 1,
    hit_invuln_t = 20
  },
  basic_better = {
    spr = { 16, 17 },
    w = 8,
    h = 8,
    spd = 0.8,
    hp = 2,
    score = 10,
    sfx_death = SFX_ENEMY_DEATH,
    base_col = 11,
    mod_col = 9,
    drop_table = {
      { min = 80, max = 100, key = "hp" },
      { min = 1, max = 5, key = "coin" }
    },
    anim_rate = 6,
    dmg = 1,
    hit_invuln_t = 20
  },
  basic_fast = {
    spr = { 16, 17 },
    w = 8,
    h = 8,
    spd = 1.35,
    hp = 1,
    score = 20,
    sfx_death = SFX_ENEMY_DEATH,
    base_col = 11,
    mod_col = 10,
    drop_table = {
      { min = 85, max = 100, key = "hp" },
      { min = 1, max = 15, key = "coin" }
    },
    anim_rate = 4,
    dmg = 1,
    hit_invuln_t = 10
  },
  basic_fatty = {
    spr = { 16, 17 },
    w = 12,
    h = 12,
    spd = 0.25,
    hp = 4,
    score = 20,
    sfx_death = SFX_ENEMY_DEATH,
    base_col = 11,
    mod_col = 8,
    drop_table = {
      { min = 70, max = 100, key = "hp" },
      { min = 1, max = 25, key = "coin" }
    },
    anim_rate = 14,
    dmg = 2,
    hit_invuln_t = 30
  }
}

wave_defs = {
  -- [level] = { wave = { { kind = "enemy_kind", weight = n } }, spawn_min = x, spawn_max = y, all_at_once = bool, all_at_once_amount = n, bg_color = c }
  [1] = {
    wave = { { kind = "basic", weight = 1 } },
    spawn_min = 30,
    spawn_max = 90,
    bg_color = 3
  },
  [2] = {
    wave = {
      { kind = "basic", weight = 100 },
      { kind = "basic_better", weight = 10 }
    },
    spawn_min = 30,
    spawn_max = 85,
    all_at_once = true,
    all_at_once_amount = 10
  },
  [3] = {
    wave = {
      { kind = "basic", weight = 100 },
      { kind = "basic_better", weight = 20 },
      { kind = "basic_fast", weight = 5 }
    },
    spawn_min = 30,
    spawn_max = 80
  },
  [4] = {
    wave = {
      { kind = "basic", weight = 100 },
      { kind = "basic_better", weight = 20 },
      { kind = "basic_fast", weight = 10 }
    },
    spawn_min = 20,
    spawn_max = 70
  },
  [5] = {
    wave = {
      { kind = "basic", weight = 100 },
      { kind = "basic_better", weight = 30 },
      { kind = "basic_fast", weight = 15 },
      { kind = "basic_fatty", weight = 10 }
    },
    spawn_min = 25,
    spawn_max = 76
  }
}

-- spawn timing and bounds
enemy_spawner = {
  spawn_min = 30,
  spawn_max = 90,
  spawn_margin = 8
}

-- pickup definitions dropped by enemies
pickup_defs = {
  hp = {
    frames = { 64, 65 },
    anim_rate = 8,
    heal = 1,
    score = 25,
    t = 120,
    sfx = SFX_PICKUP_HEALTH
  },
  coin = {
    frames = { 66, 67, 68, 69 },
    anim_rate = 6,
    t = 360,
    score = 100,
    sfx = SFX_PICKUP_COIN
  }
}

-- create a new enemy just offscreen and add to the list
function spawn_enemy(kind_override)
  -- get a random enemy kind for the current level
  local wave_kind = pick_wave_kind(game_state.current_wave)

  kind = kind_override or wave_kind or "basic"

  local def = enemy_types[kind] or enemy_types.basic

  local w = 128
  local h = 128 - UI_HEIGHT - MARGIN_BOTTOM
  local side = flr(rnd(4))

  local x, y
  if side == 0 then
    x = -def.w - enemy_spawner.spawn_margin
    y = rnd(h)
  elseif side == 1 then
    x = w + enemy_spawner.spawn_margin
    y = rnd(h)
  elseif side == 2 then
    x = rnd(w)
    y = -def.h - enemy_spawner.spawn_margin
  else
    x = rnd(w)
    y = h + enemy_spawner.spawn_margin
  end

  local e = {
    x = x,
    y = y,
    kind = kind,
    spr = def.spr,
    anim_i = 1,
    anim_t = 0,
    w = def.w,
    h = def.h,
    spd = def.spd,
    hp = def.hp,
    score = def.score or 0,
    drop_table = def.drop_table,
    base_col = def.base_col,
    mod_col = def.mod_col,
    hit_flash = nil
  }
  add(game_state.enemies, e)
end

function pick_wave_kind(wave_options)
  if not wave_options or #wave_options == 0 then
    return nil
  end

  local total = 0
  for opt in all(wave_options) do
    if type(opt) == "table" then
      total += (opt.weight or 1)
    else
      total += 1
    end
  end

  if total <= 0 then
    return wave_options[1]
  end

  local roll = rnd(total)
  local acc = 0
  for opt in all(wave_options) do
    local w = 1
    local kind = opt
    if type(opt) == "table" then
      w = opt.weight or 1
      kind = opt.kind
    end
    acc += w
    if roll < acc then
      return kind
    end
  end

  local last = wave_options[#wave_options]
  if type(last) == "table" then
    return last.kind
  end
  return last
end

function spawn_enemy_ring(count)
  count = count or 0
  if count <= 0 then
    return
  end
  local cx = 64
  local cy = (128 - UI_HEIGHT - MARGIN_BOTTOM) / 2
  local r = 84
  local offset = rnd(1) * 6.2831853
  for i = 1, count do
    local theta = offset + ((i - 1) / count) * 6.2831853
    local x = cx + cos(theta) * r
    local y = cy + sin(theta) * r
    local w = 128
    local h = 128 - UI_HEIGHT - MARGIN_BOTTOM
    if x < -8 then x = -8 end
    if x > w + 8 then x = w + 8 end
    if y < -8 then y = -8 end
    if y > h + 8 then y = h + 8 end

    local kind = pick_wave_kind(game_state.current_wave) or "basic"
    local def = enemy_types[kind] or enemy_types.basic
    local e = {
      x = x,
      y = y,
      kind = kind,
      spr = def.spr,
      anim_i = 1,
      anim_t = 0,
      w = def.w,
      h = def.h,
      spd = def.spd,
      hp = def.hp,
      score = def.score or 0,
      drop_table = def.drop_table,
      base_col = def.base_col,
      mod_col = def.mod_col,
      hit_flash = nil
    }
    add(game_state.enemies, e)
  end
end

-- roll a drop table and return a pickup key or nil
function roll_drop(drop_table)
  if not drop_table then
    return nil
  end
  local r = flr(rnd(100)) + 1
  for e in all(drop_table) do
    if r >= e.min and r <= e.max then
      return e.key
    end
  end
  return nil
end

-- spawn a pickup at a position
function spawn_pickup(key, x, y)
  local def = pickup_defs[key]
  if not def then
    return
  end
  local p = { key = key, x = x, y = y, t = def.t or 60, anim_i = 1, anim_t = 0 }
  add(game_state.pickups, p)
end

-- handle a defeated enemy drop
function enemy_drop(enemy)
  local key = roll_drop(enemy.drop_table)
  if key then
    spawn_pickup(key, enemy.x + 4, enemy.y + 4)
  end
end

-- update pickup animation, lifetime, and player collection
function update_pickups()
  for i = #game_state.pickups, 1, -1 do
    local p = game_state.pickups[i]
    local def = pickup_defs[p.key]
    if not def then
      deli(game_state.pickups, i)
      -- continue
    else
      local frames = def.frames
      if frames and #frames > 1 then
        p.anim_t += 1
        if (p.anim_t % (def.anim_rate or 8)) == 0 then
          p.anim_i = (p.anim_i % #frames) + 1
        end
      end

      p.t -= 1
      if p.t <= 0 then
        deli(game_state.pickups, i)
      else
        if aabb(game_state.player.position.x, game_state.player.position.y, 8, 8, p.x - 2, p.y - 2, 4, 4) then
          if p.key == "hp" then
            local heal = def.heal or 1
            local hp_max = (game_state.player.cfg and game_state.player.cfg.hp_max) or 3
            if game_state.player.hp >= hp_max then
              local score = def.score or 0
              if score > 0 then
                game_state.score += score
                game_state.toast = "+" .. score
                game_state.toast_t = 30
              end
            else
              game_state.player.hp = min(hp_max, game_state.player.hp + heal)
              game_state.toast = "hp +" .. heal
              game_state.toast_t = 30
            end
          elseif def.score and def.score > 0 then
            game_state.score += def.score
            game_state.toast = "+" .. def.score
            game_state.toast_t = 30
          end
          if def.sfx ~= nil then
            sfx(def.sfx)
          end
          deli(game_state.pickups, i)
        end
      end
    end
  end
end

-- draw pickups
function draw_pickups()
  for p in all(game_state.pickups) do
    local def = pickup_defs[p.key]
    if def then
      local x = flr(p.x + 0.5)
      local y = flr(p.y + 0.5)
      local frames = def.frames
      local spr_id = frames and frames[p.anim_i] or 0
      spr(spr_id, x - 4, y - 4)
    end
  end
end

-- update enemy spawn timing, movement, and collisions
function update_enemies()
  if game_state.game_over then
    return
  end

  if game_state.spawn_enabled == false and #game_state.enemies == 0 then
    game_state.spawn_enabled = true
    game_state.enemy_spawn_t = 0
  end

  -- spawn timer uses level def values when set
  local base_min = game_state.spawn_min or enemy_spawner.spawn_min
  local base_max = game_state.spawn_max or enemy_spawner.spawn_max
  local min_t = max(1, base_min)
  local max_t = max(min_t, base_max)

  if game_state.spawn_enabled ~= false then
    if game_state.enemy_spawn_t > 0 then
      game_state.enemy_spawn_t -= 1
    else
      spawn_enemy()
      game_state.enemy_spawn_t = flr(rnd(max_t - min_t + 1)) + min_t
    end
  end

  -- chase the player center
  local px = game_state.player.position.x + 4
  local py = game_state.player.position.y + 4

  for i = #game_state.enemies, 1, -1 do
    local e = game_state.enemies[i]
    local def = enemy_types[e.kind] or enemy_types.basic
    local frames = e.spr
    -- animate enemy sprite frames
    if type(frames) == "table" then
      local n = #frames
      if n > 0 then
        e.anim_t += 1
        if (e.anim_t % (def.anim_rate or 8)) == 0 then
          e.anim_i = (e.anim_i % n) + 1
        end
      end
    end

    -- move toward player
    local ex = e.x + 4
    local ey = e.y + 4
    local dx = px - ex
    local dy = py - ey
    local d = sqrt(dx * dx + dy * dy)
    if d > 0 then
      e.x += (dx / d) * e.spd
      e.y += (dy / d) * e.spd
    end

    -- handle collision with player
    if aabb(e.x, e.y, e.w, e.h, game_state.player.position.x, game_state.player.position.y, 8, 8) then
      if player_hit(def.dmg or 1, def.hit_invuln_t) then
        deli(game_state.enemies, i)
        if game_state.player.hp <= 0 then
          return
        end
      end
    end
  end
end

function enemy_take_damage(enemy, dmg, idx)
  if not enemy then
    return false
  end

  dmg = dmg or 1
  enemy.hp = (enemy.hp or 1) - dmg
  local base_col = enemy.base_col or 12
  enemy.hit_flash = add_hit_flash(8, base_col, 8)
  sfx(SFX_PLAYER_HIT)
  if enemy.hp <= 0 then
    local def = enemy_types[enemy.kind]
    if def and def.sfx_death ~= nil then
      sfx(def.sfx_death)
    end
    game_state.score += enemy.score or 0
    enemy_drop(enemy)
    if idx then
      deli(game_state.enemies, idx)
    else
      for i = #game_state.enemies, 1, -1 do
        if game_state.enemies[i] == enemy then
          deli(game_state.enemies, i)
          break
        end
      end
    end
    return true
  end
  return true
end

-- draw enemies
function draw_enemies()
  for e in all(game_state.enemies) do
    local frames = e.spr
    local spr_id = frames
    if type(frames) == "table" then
      spr_id = frames[e.anim_i] or frames[1]
    end
    local base_col = e.base_col or 12
    draw_sprite_hit_effect(spr_id, flr(e.x + 0.5), flr(e.y + 0.5), e.hit_flash, base_col, e.mod_col)
  end
end