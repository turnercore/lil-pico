-- constants
-- colors: 0-15: black,1:dark blue,2:dark purple,3:dark green,4:brown,5:dark gray,
-- 6:light gray,7:white,8:dark red,9:orange,10:yellow,11:green,12:blue,13:indigo,14:cyan,15:pink
UI_COLOR = 5
UI_HEIGHT = 16

function ui_print_centered(msg, y, col)
  col = col or 7
  local x = flr((128 - (#msg * 4)) / 2)
  if x < 0 then x = 0 end
  print(msg, x, y, col)
end

function draw_score()
  -- Example logic to draw the score
  print("Score: " .. game_state.score, 1, 128 - UI_HEIGHT + 2, 7)
end

function draw_level()
  -- Example logic to draw the level
  print("Level: " .. game_state.level, 1, 128 - UI_HEIGHT + 10, 7)
end

function draw_health()
  local hp_max = (game_state.player.cfg and game_state.player.cfg.hp_max) or 3
  local hp = game_state.player.hp or 0
  local x = 60
  local y = 128 - UI_HEIGHT + 2
  local size = 4
  local gap = 2
  local max_hp = max(0, hp_max)
  for i = 1, max_hp do
    local sx = x + (i - 1) * (size + gap)
    rect(sx, y, sx + size, y + size, 7)
    if i <= hp then
      rectfill(sx + 1, y + 1, sx + size - 1, y + size - 1, 8)
    end
  end
end

function draw_ui()
  -- draw bottom UI bar
  rectfill(0, 128 - UI_HEIGHT, 127, 127, UI_COLOR)
  draw_level_progress()
  draw_score()
  draw_health()
  draw_level()

  -- draw toast messages, if any
  draw_toast()
end

function draw_level_progress()
  local lvl = game_state.level or 1
  local need = level_score_req and level_score_req[lvl] or nil
  if not need or need <= 0 then
    return
  end

  local start = game_state.level_score_start or 0
  local cur = game_state.score or 0
  local denom = need - start
  if denom <= 0 then
    return
  end

  local t = (cur - start) / denom
  if t < 0 then t = 0 end
  if t > 1 then t = 1 end

  local y = 128 - UI_HEIGHT
  local w = flr(128 * t)
  if w > 0 then
    rectfill(0, y, w - 1, y, 11)
  end
end

function draw_toast()
  if game_state.toast_t > 0 and game_state.toast ~= "" then
    local x = flr((128 - (#game_state.toast * 4)) / 2)
    if x < 0 then x = 0 end
    print(game_state.toast, x, 1, 7)
  end
end

function update_toast()
  if game_state.toast_t > 0 then
    game_state.toast_t -= 1
    if game_state.toast_t <= 0 then
      game_state.toast_t = 0
      game_state.toast = ""
    end
  end
end

function ui_draw_main_menu()
  ui_print_centered("lil pico", 32, 7)
  ui_print_centered("press X or O to start", 52, 6)
end

function ui_draw_upgrades()
  local panel_y = 16
  rectfill(8, panel_y, 119, 88, 1)
  rect(8, panel_y, 119, 88, 7)
  ui_print_centered("choose upgrade", panel_y + 4, 7)

  local choices = game_state.upgrade_choices or {}
  local idx = game_state.upgrade_index or 1
  for i = 1, #choices do
    local u = choices[i]
    local y = panel_y + 16 + (i - 1) * 18
    local is_sel = (i == idx)
    local col = is_sel and 10 or 6
    local title = u and u.title or "?"
    local desc = u and u.desc or ""
    rectfill(14, y - 2, 113, y + 14, is_sel and 3 or 0)
    print(title, 18, y, col)
    print(desc, 18, y + 8, 6)
  end

  ui_print_centered("up/down + X", 94, 6)
end

function ui_draw_game_over()
  ui_print_centered("game over", 32, 7)
  ui_print_centered("final score: " .. game_state.score, 44, 7)
  ui_print_centered("hold O+X to restart", 56, 6)
end
