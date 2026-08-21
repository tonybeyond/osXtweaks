-- modules/reload.lua
-- Rechargement automatique de la config à chaque sauvegarde d'un .lua.
--
-- Le watcher DOIT être référencé depuis une variable globale (ici HS.watchers).
-- Sinon le garbage collector Lua le détruit au bout de quelques minutes et le
-- rechargement cesse silencieusement.
-- Réf : Hammerspoon issue #1103 — "all watchers and timers should be captured
-- in a global variable".

local M = {}

function M.init()
  HS.watchers.config = hs.pathwatcher.new(
    os.getenv("HOME") .. "/.hammerspoon/",
    function(files)
      for _, f in ipairs(files) do
        if f:sub(-4) == ".lua" then
          hs.reload()
          return
        end
      end
    end
  ):start()
end

--- Eventtap de diagnostic : affiche dans la console les modificateurs reçus.
-- À appeler depuis la console Hammerspoon si un raccourci ne réagit pas :
--   require("modules.reload").debugModifiers()
-- Sert notamment à vérifier que Hyperkey envoie bien shift = true.
function M.debugModifiers()
  HS.watchers.modDebug = hs.eventtap.new(
    { hs.eventtap.event.types.keyDown },
    function(e)
      print(hs.inspect(e:getFlags()), hs.keycodes.map[e:getKeyCode()])
    end
  ):start()
  hs.alert.show("Diagnostic modificateurs actif — voir la console")
end

return M
