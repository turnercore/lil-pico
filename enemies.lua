-- enemy config: stats, sprites, drops
enemy_types = {
  basic = {
    spr = { 16, 17 },
    w = 8,
    h = 8,
    spd = 0.6,
    hp = 1,
    score = 10,
    drop_table = {
      { min = 90, max = 100, key = "hp" }
    },
    anim_rate = 8,
    dmg = 1,
    hit_invuln_t = 20
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
    t = 80
  }
}

-- create a new enemy just offscreen and add to the list
function spawn_enemy(kind)
  kind = kind or "basic"
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
    drop_table = def.drop_table
  }
  add(game_state.enemies, e)
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
            game_state.player.hp = min(hp_max, game_state.player.hp + heal)
            game_state.toast = "hp +" .. heal
            game_state.toast_t = 30
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

  -- spawn timer scales with level
  local lvl = game_state.level or 1
  local min_t = max(10, enemy_spawner.spawn_min - (lvl - 1) * 2)
  local max_t = max(min_t, enemy_spawner.spawn_max - (lvl - 1) * 4)

  if game_state.enemy_spawn_t > 0 then
    game_state.enemy_spawn_t -= 1
  else
    spawn_enemy()
    game_state.enemy_spawn_t = flr(rnd(max_t - min_t + 1)) + min_t
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

-- draw enemies
function draw_enemies()
  for e in all(game_state.enemies) do
    local frames = e.spr
    local spr_id = frames
    if type(frames) == "table" then
      spr_id = frames[e.anim_i] or frames[1]
    end
    spr(spr_id, flr(e.x + 0.5), flr(e.y + 0.5))
  end
end