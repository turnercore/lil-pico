-- constants
MARGIN_BOTTOM = 5
local screen_w, screen_h = 128, 128 - UI_HEIGHT - MARGIN_BOTTOM

function _init()
    init_game_state()
    init_app_state()
    start_bgm(0)
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
    local need = flr(20 + (lvl * lvl) * 5)
    if game_state.score >= need then
        game_state.level = lvl + 1
        game_state.toast = "level " .. game_state.level
        game_state.toast_t = 30
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
