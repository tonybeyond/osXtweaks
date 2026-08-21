-- ~/.hammerspoon/init.lua
--
-- La touche Hyper (⌃⌥⇧⌘) est produite par Hyperkey.app.
-- Hammerspoon se contente de l'écouter : il ne remappe pas Caps Lock.

hs.window.animationDuration = 0

-- Table globale : conteneur de tous les objets qui doivent survivre au
-- garbage collector Lua (hotkeys, watchers, eventtaps).
HS = HS or { hotkeys = {}, watchers = {} }

hyper = { "ctrl", "alt", "shift", "cmd" }

require("modules.apps").init(hyper)
require("modules.windows").init(hyper)
require("modules.reload").init()

hs.alert.show("Hammerspoon ✓ " .. #HS.hotkeys .. " raccourcis")
