function toast_show(msg, frames)
  game_state.toast = msg or ""
  game_state.toast_t = frames or 0
end

function toast_clear()
  game_state.toast = ""
  game_state.toast_t = 0
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
      toast_clear()
    end
  end
end
