-- constants
MARGIN_BOTTOM = 5
local screen_w, screen_h = 128, 128 - UI_HEIGHT - MARGIN_BOTTOM

function _init()
    -- Initialize game state
    init_game_state()
    start_bgm(0)
end

function _update()
    if game_state.game_over then
        -- restart on holding both action buttons
        if btn(4) and btn(5) then
            reset_game_state()
            start_bgm(0)
        else
            update_toast()
        end
        return
    end

    -- Update game logic
    update_player_position()
    update_player_animation()
    update_player_actions()
    update_projectiles()
    update_enemies()
    update_pickups()
    update_toast()
    check_level_progression()
end

function _draw()
    -- Render game state
    cls()
    if not game_state.player.dead then
        draw_player()
    end
    draw_projectiles()
    draw_enemies()
    draw_pickups()
    draw_ui()

    if game_state.game_over then
        local msg = "game over"
        local x = flr((128 - (#msg * 4)) / 2)
        print(msg, x, 32, 7)

        local score_msg = "final score: " .. game_state.score
        local sx = flr((128 - (#score_msg * 4)) / 2)
        print(score_msg, sx, 44, 7)

        local prompt = "hold O+X to restart"
        local px = flr((128 - (#prompt * 4)) / 2)
        print(prompt, px, 56, 6)
    end
end

function start_bgm(music_id)
    music(music_id)
end

function set_game_over()
    if game_state.game_over then
        return
    end

    game_state.game_over = true
    game_state.player.dead = true
    game_state.enemies = {}
    game_state.projectiles = {}
    game_state.pickups = {}
    game_state.toast = "game over"
    game_state.toast_t = 9999
    music(-1)
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
    end
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
