local screen_w, screen_h = 128, 128 - UI_HEIGHT - MARGIN_BOTTOM
level_score_req = {
    -- [current_level] = score_needed_for_next_level
    [1] = 40,
    [2] = 125,
    [3] = 175,
    [4] = 350,
    [5] = 500,
    [6] = 800,
    [7] = 1200,
    [8] = 1700,
    [9] = 2300,
    [10] = 3000,
    [11] = 4000,
    [12] = 5500,
    [13] = 7500,
    [14] = 10000,
    [15] = 13000
}

function _init()
    init_game_state()
    init_app_state()
    start_bgm(MUSIC_BGM_MAIN)
end

function _update()
    update_app_state()
end

function _draw()
    draw_app_state()
end

function start_bgm(music_id)
    music(music_id)
end

-- hit flash helpers
function add_hit_flash(frames, base_col, flash_col)
    local t = frames or 0
    if t <= 0 then
        return nil
    end
    local flash = { t = t, base_col = base_col, flash_col = flash_col }
    add(game_state.hit_flashes, flash)
    return flash
end

function update_hit_flashes()
    for i = #game_state.hit_flashes, 1, -1 do
        local f = game_state.hit_flashes[i]
        f.t -= 1
        if f.t <= 0 then
            deli(game_state.hit_flashes, i)
        end
    end
end

-- draw a sprite with a brief hit-flash palette swap
function draw_sprite_hit_effect(spr_id, x, y, flash, base_col, mod_col, w, h, flipx, flipy)
    w = w or 1
    h = h or 1
    local use_base = base_col or (flash and flash.base_col)
    if flash and flash.t > 0 and (flash.t % 4) < 2 then
        if use_base and flash.flash_col then
            pal(use_base, flash.flash_col)
        end
        spr(spr_id, x, y, w, h, flipx, flipy)
        pal()
        return
    end

    if mod_col and use_base and mod_col ~= use_base then
        pal(use_base, mod_col)
        spr(spr_id, x, y, w, h, flipx, flipy)
        pal()
        return
    end

    spr(spr_id, x, y, w, h, flipx, flipy)
end

function wrap_xy(x, y, w, h)
    w = w or 0
    h = h or 0
    local max_x = screen_w - 1
    local max_y = screen_h - 1
    if x < -w then x = max_x end
    if x > max_x then x = -w end
    if y < -h then y = max_y end
    if y > max_y then y = -h end
    return x, y
end

function is_offscreen_xy(x, y, w, h, margin)
    w = w or 0
    h = h or 0
    margin = margin or 0
    return x + w < -margin or x > (screen_w - 1 + margin) or y + h < -margin or y > (screen_h - 1 + margin)
end

function check_level_progression()
    local lvl = game_state.level or 1
    local need = level_score_req[lvl]
    if need and game_state.score >= need then
        set_level(lvl + 1)
        return true
    end
    return false
end

function aabb(ax, ay, aw, ah, bx, by, bw, bh)
    return ax < bx + bw and bx < ax + aw and ay < by + bh and by < ay + ah
end

function point_in_rect(px, py, rx, ry, rw, rh)
    return px >= rx and px < rx + rw and py >= ry and py < ry + rh
end

function random_int_range(min, max)
    return flr(rnd(max - min + 1)) + min
end