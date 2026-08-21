-- modules/util.lua
-- Helpers partagés. Tout objet persistant est stocké dans la table globale HS
-- pour échapper au garbage collector Lua.
-- Réf : https://www.hammerspoon.org/go/ ("A quick aside about variable lifecycles")

local M = {}

--- Enregistre un hotkey et conserve une référence globale.
-- @param mods table  liste de modificateurs, ex. { "ctrl", "alt", "shift", "cmd" }
-- @param key  string touche, ex. "t"
-- @param fn   function callback
function M.bind(mods, key, fn)
  local hk = hs.hotkey.bind(mods, key, fn)
  table.insert(HS.hotkeys, hk)
  return hk
end

return M
