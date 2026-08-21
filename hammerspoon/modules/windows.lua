-- modules/windows.lua
-- Gestion de fenêtres. Remplace Rectangle / Magnet.

local util = require("modules.util")

local M = {}

--- Positionne la fenêtre active en fractions de l'écran courant.
-- @param x,y,w,h number  fractions entre 0 et 1
local function moveTo(x, y, w, h)
  return function()
    local win = hs.window.focusedWindow()
    if not win then
      hs.alert.show("Aucune fenêtre active")
      return
    end
    local f = win:screen():frame()
    win:setFrame({
      x = f.x + (f.w * x),
      y = f.y + (f.h * y),
      w = f.w * w,
      h = f.h * h,
    })
  end
end

M.layouts = {
  { key = "left",   frame = { 0,    0,    0.5,  1    } },
  { key = "right",  frame = { 0.5,  0,    0.5,  1    } },
  { key = "up",     frame = { 0,    0,    1,    0.5  } },
  { key = "down",   frame = { 0,    0.5,  1,    0.5  } },
  { key = "return", frame = { 0,    0,    1,    1    } },
  { key = "c",      frame = { 0.15, 0.10, 0.70, 0.80 } },
}

function M.init(hyper)
  for _, l in ipairs(M.layouts) do
    util.bind(hyper, l.key, moveTo(table.unpack(l.frame)))
  end

  -- Envoyer la fenêtre active sur l'écran suivant
  util.bind(hyper, "n", function()
    local win = hs.window.focusedWindow()
    if not win then
      hs.alert.show("Aucune fenêtre active")
      return
    end
    win:moveToScreen(win:screen():next(), false, true)
  end)
end

return M
