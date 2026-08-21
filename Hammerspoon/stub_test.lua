-- Stub de l'API hs : vérifie la logique pure-Lua sans macOS.
local bound, alerts, reloaded = {}, {}, false

local function fakeApp(name, opts)
  opts = opts or {}
  return {
    isFrontmost   = function() return opts.frontmost or false end,
    hide          = function() alerts[#alerts+1] = "HIDE:"..name end,
    activate      = function() alerts[#alerts+1] = "ACTIVATE:"..name end,
    allWindows    = function() return opts.windows or {} end,
    selectMenuItem= function(_, path)
                      alerts[#alerts+1] = "MENU:"..name..":"..table.concat(path," > ")
                      return opts.menuOK ~= false
                    end,
  }
end

local registry = {}  -- pilote hs.application.get

hs = {
  window = { animationDuration = 0, focusedWindow = function() return nil end },
  hotkey = { bind = function(m,k,f) bound[#bound+1] = {key=k, fn=f}; return {k} end },
  application = {
    get = function(n) return registry[n] end,
    launchOrFocus = function(n) alerts[#alerts+1] = "LAUNCH:"..n; return registry[n] ~= nil or n ~= "Inexistante" end,
  },
  alert = { show = function(s) alerts[#alerts+1] = "ALERT:"..s end },
  pathwatcher = { new = function(p, f) return { start = function(self) f({"/x/init.lua"}); return self end } end },
  reload = function() reloaded = true end,
  eventtap = { event = { types = { keyDown = 1 } }, new = function() return { start=function(s) return s end } end },
  inspect = tostring, keycodes = { map = {} },
}

dofile(os.getenv("REPO_ROOT") or "init.lua")

local function press(key)
  for _, b in ipairs(bound) do if b.key == key then b.fn(); return true end end
  return false
end

local fails = 0
local function check(label, cond)
  print((cond and "  PASS  " or "  FAIL  ") .. label)
  if not cond then fails = fails + 1 end
end

print("== inventaire ==")
local keys = {}
for _, b in ipairs(bound) do keys[#keys+1] = b.key end
table.sort(keys)
print("  " .. table.concat(keys, " "))
check("12 raccourcis enregistres", #bound == 12)

local seen, dup = {}, false
for _, k in ipairs(keys) do if seen[k] then dup = true; print("  DOUBLON: "..k) end seen[k] = true end
check("aucun doublon de touche", not dup)

check("watcher capture dans HS.watchers", HS.watchers.config ~= nil)
check("pathwatcher a declenche hs.reload", reloaded)

print("== Finder: process systeme absent -> pas de launch ==")
alerts = {}; registry = {}
press("f")
check("alerte 'process systeme introuvable'", alerts[1] and alerts[1]:match("process syst"))
check("aucun LAUNCH tente", not (alerts[1] or ""):match("LAUNCH"))

print("== Finder: lance sans fenetre -> menu 'New Finder Window' ==")
alerts = {}; registry = { Finder = fakeApp("Finder", { windows = {} }) }
press("f")
check("menu Finder correct", alerts[2] == "MENU:Finder:File > New Finder Window")

print("== Ghostty: absent -> launchOrFocus ==")
alerts = {}; registry = {}
press("t")
check("LAUNCH:Ghostty", alerts[1] == "LAUNCH:Ghostty")

print("== Ghostty: au premier plan -> hide ==")
alerts = {}; registry = { Ghostty = fakeApp("Ghostty", { frontmost = true, windows = {1} }) }
press("t")
check("HIDE:Ghostty", alerts[1] == "HIDE:Ghostty")

print("== Ghostty: en arriere-plan avec fenetre -> activate ==")
alerts = {}; registry = { Ghostty = fakeApp("Ghostty", { windows = {1} }) }
press("t")
check("ACTIVATE:Ghostty", alerts[1] == "ACTIVATE:Ghostty")

print("== Ghostty: lance sans fenetre, menu absent -> alerte ==")
alerts = {}; registry = { Ghostty = fakeApp("Ghostty", { windows = {}, menuOK = false }) }
press("t")
check("alerte menu introuvable", alerts[3] and alerts[3]:match("introuvable"))

print("== windows: aucune fenetre active -> alerte, pas de crash ==")
alerts = {}
press("left")
check("alerte 'Aucune fenetre active'", alerts[1] == "ALERT:Aucune fenêtre active")

print(fails == 0 and "\nTOUS LES TESTS PASSENT" or ("\n" .. fails .. " ECHEC(S)"))
os.exit(fails == 0 and 0 or 1)
