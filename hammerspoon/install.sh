#!/usr/bin/env bash
# Lie ce dépôt à ~/.hammerspoon.
# Idempotent : relançable sans effet de bord.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="$HOME/.hammerspoon"

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "Ce script cible macOS uniquement (uname -s = $(uname -s))." >&2
  exit 1
fi

if [[ -L "$TARGET" ]]; then
  current="$(readlink "$TARGET")"
  if [[ "$current" == "$REPO" ]]; then
    echo "Déjà lié : $TARGET -> $REPO"
  else
    echo "Remplacement du lien existant ($current -> $REPO)"
    ln -sfn "$REPO" "$TARGET"
  fi
elif [[ -d "$TARGET" ]]; then
  backup="$TARGET.bak.$(date +%Y%m%d%H%M%S)"
  echo "Config existante déplacée vers $backup"
  mv "$TARGET" "$backup"
  ln -s "$REPO" "$TARGET"
else
  ln -s "$REPO" "$TARGET"
  echo "Lié : $TARGET -> $REPO"
fi

if ! command -v hs >/dev/null 2>&1 && [[ ! -d /Applications/Hammerspoon.app ]]; then
  echo
  echo "Hammerspoon n'est pas installé. Lance :"
  echo "  brew install --cask hammerspoon"
  exit 0
fi

echo
echo "Recharge la config : icône barre de menu -> Reload Config"
echo "Vérifie les noms d'applications avec :"
echo "  for a in /Applications/*.app; do basename \"\$a\" .app; done"
