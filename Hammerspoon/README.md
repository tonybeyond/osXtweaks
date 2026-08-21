# hammerspoon

Config [Hammerspoon](https://www.hammerspoon.org/) pilotée par la touche **Hyper** (`⌃⌥⇧⌘`) : lancement d'applications et gestion de fenêtres.

Hammerspoon ne produit pas le Hyper. Il l'écoute. Le remap `Caps Lock → ⌃⌥⇧⌘` est assuré en amont par [Hyperkey](https://hyperkey.app/) (ou Karabiner-Elements).

## Raccourcis

Tous préfixés par **Hyper** (`Caps Lock` maintenu).

### Applications

Second appui = masquer l'application.

| Touche | Application |
|---|---|
| `A` | AFFiNE |
| `B` | Brave Browser |
| `F` | Finder |
| `T` | Ghostty |
| `Z` | Zed |

### Fenêtres

| Touche | Action |
|---|---|
| `←` | Moitié gauche |
| `→` | Moitié droite |
| `↑` | Moitié haute |
| `↓` | Moitié basse |
| `⏎` | Plein écran |
| `C` | Centrer (70 × 80 %) |
| `N` | Envoyer sur l'écran suivant |

## Installation

```bash
brew install --cask hammerspoon
git clone git@github.com:<user>/hammerspoon.git ~/src/hammerspoon
~/src/hammerspoon/install.sh
```

`install.sh` crée le lien `~/.hammerspoon → <dépôt>` et sauvegarde toute config existante en `~/.hammerspoon.bak.<timestamp>`.

Au premier lancement, accorder l'accès **Accessibilité** : Réglages Système → Confidentialité et sécurité → Accessibilité.

## Configuration

Les applications se déclarent dans `modules/apps.lua` :

```lua
M.config = {
  t = { name = "Ghostty", newWindow = { "File", "New Window" } },
}
```

| Champ | Rôle |
|---|---|
| `name` | Nom du bundle sans `.app`, ou bundle ID |
| `newWindow` | Chemin de menu pour recréer une fenêtre quand l'app tourne sans fenêtre |
| `system` | Process géré par launchd — interdit toute tentative de lancement |
| `noHide` | Désactive le masquage au second appui |

Le fichier est rechargé automatiquement à la sauvegarde (`modules/reload.lua`).

Récupérer les noms exacts :

```bash
for a in /Applications/*.app; do basename "$a" .app; done
```

Cette forme évite les artefacts de `ls` (couleurs ANSI, quoting shell-escape) qui cassent un `sed 's|\.app$||'`.

Si le nom échoue, utiliser le bundle ID — `hs.application.get()` accepte les deux :

```bash
osascript -e 'id of app "Ghostty"'
```

## Notes de conception

**Finder n'est pas dans `/Applications`.** Son bundle vit dans `/System/Library/CoreServices/Finder.app` et launchd le maintient en vie en permanence. Deux conséquences dans le code :

- `system = true` : si `hs.application.get("Finder")` renvoie `nil`, c'est une anomalie système. Le code alerte au lieu de tenter un lancement qui masquerait le problème.
- Son intitulé de menu est `New Finder Window`, pas `New Window`. D'où le champ `newWindow` par application plutôt qu'une chaîne codée en dur.

**Tous les objets persistants sont stockés dans la table globale `HS`.** Un `hs.pathwatcher` ou un `hs.eventtap` conservé dans une variable `local` est ramassé par le garbage collector Lua au bout de quelques minutes et cesse de fonctionner sans message d'erreur. Voir [Hammerspoon issue #1103](https://github.com/Hammerspoon/hammerspoon/issues/1103) et la section *variable lifecycles* de [hammerspoon.org/go](https://www.hammerspoon.org/go/).

**Aucun échec silencieux.** `launchOrFocus` et `selectMenuItem` renvoient un booléen : chaque retour est testé et produit une alerte visible.

## Tests

```bash
make check   # luac -p sur tous les .lua, bash -n sur install.sh
make test    # exécute la logique contre un stub de l'API hs
```

`test/stub_test.lua` remplace le module `hs` par un double et vérifie l'inventaire des raccourcis, l'absence de doublons, la capture du watcher, et les branches de bascule (absent / premier plan / arrière-plan / sans fenêtre) — sans macOS. Prérequis : `lua5.4`.

## Diagnostic

Si un raccourci ne réagit pas, vérifier que Hyperkey envoie bien les quatre modificateurs. Dans la console Hammerspoon :

```lua
require("modules.reload").debugModifiers()
```

Presser Hyper+A. Sortie attendue :

```
{ alt = true, cmd = true, ctrl = true, shift = true }	a
```

Si `shift` manque, cocher **Include Shift in Hyper Key** dans Hyperkey, ou adapter `hyper` dans `init.lua`.

## Arborescence

```
.
├── init.lua              # point d'entrée : globales, chargement des modules
├── install.sh            # lien symbolique vers ~/.hammerspoon
├── Makefile              # check / test
├── modules/
│   ├── apps.lua          # lancement et bascule d'applications
│   ├── windows.lua       # positionnement de fenêtres
│   ├── reload.lua        # rechargement auto + diagnostic modificateurs
│   └── util.lua          # bind() avec protection contre le GC
└── test/
    └── stub_test.lua
```

## Licence

MIT
