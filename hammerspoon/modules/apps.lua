-- modules/apps.lua
-- Lancement / bascule d'applications via la touche Hyper.

local util = require("modules.util")

local M = {}

-- Configuration des applications.
--   name      : nom du bundle (sans .app) OU bundle ID
--   newWindow : chemin de menu pour recréer une fenêtre quand l'app tourne
--               sans fenêtre ouverte. Omettre si l'app n'en a pas.
--   system    : true pour un process système géré par launchd (Finder, Dock).
--               Empêche toute tentative de lancement : si le process est
--               absent, c'est une anomalie, pas un cas à corriger en silence.
--   noHide    : true pour désactiver le masquage au second appui.
M.config = {
  t = { name = "Ghostty",       newWindow = { "File", "New Window" } },
  a = { name = "AFFiNE",        newWindow = { "File", "New Window" } },
  b = { name = "Brave Browser", newWindow = { "File", "New Window" } },
  z = { name = "Zed",           newWindow = { "File", "New Window" } },

  -- Finder n'est pas dans /Applications : le bundle vit dans
  -- /System/Library/CoreServices/Finder.app et launchd le maintient en vie.
  -- Son intitulé de menu diffère : "New Finder Window", pas "New Window".
  f = {
    name      = "Finder",
    newWindow = { "File", "New Finder Window" },
    system    = true,
  },
}

--- Construit le callback de bascule pour une entrée de config.
local function toggle(cfg)
  return function()
    local app = hs.application.get(cfg.name)

    -- Process absent
    if not app then
      if cfg.system then
        hs.alert.show(cfg.name .. " : process système introuvable")
        return
      end
      if not hs.application.launchOrFocus(cfg.name) then
        hs.alert.show("Introuvable : " .. cfg.name)
      end
      return
    end

    -- Déjà au premier plan -> masquer
    if app:isFrontmost() then
      if not cfg.noHide then
        app:hide()
      end
      return
    end

    -- Lancé mais sans fenêtre (fréquent après un Cmd+W sur Ghostty, Zed, Finder)
    if #app:allWindows() == 0 then
      app:activate()
      if cfg.newWindow then
        if not app:selectMenuItem(cfg.newWindow) then
          hs.alert.show(cfg.name .. " : menu "
            .. table.concat(cfg.newWindow, " > ") .. " introuvable")
        end
      end
      return
    end

    app:activate()
  end
end

--- Enregistre tous les raccourcis d'application.
-- @param hyper table modificateurs Hyper
function M.init(hyper)
  for key, cfg in pairs(M.config) do
    util.bind(hyper, key, toggle(cfg))
  end
end

return M
