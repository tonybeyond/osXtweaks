#!/bin/bash
# =============================================================================
#  mac-setup.sh — Configuration automatisée d'un Mac (Apple Silicon / Intel)
# -----------------------------------------------------------------------------
#  Fait :
#    1. Installe Homebrew (+ shellenv dans ~/.zprofile)
#    2. Installe les formules (zsh-autosuggestions, zsh-syntax-highlighting,
#       eza, fzf, starship, fastfetch)
#    3. Installe les apps : Brave, CleanShot X, LinearMouse, Capacities,
#       Proton Mail
#    4. Installe la police Monaco Nerd Font (~/Library/Fonts)
#    5. Installe oh-my-zsh + applique la config ZSH (starship.toml + .zshrc)
#    6. Applique les policies Brave de debloat (/Library/Managed Preferences)
#    7. Valide chaque étape et affiche un récapitulatif final
#
#  Usage :   ./mac-setup.sh        (PAS avec sudo — le mot de passe sera
#                                    demandé uniquement pour les étapes root)
# =============================================================================

set -uo pipefail   # pas de "set -e" : on gère les erreurs étape par étape

# Locale UTF-8 forcée (évite les bugs de parsing avec caractères accentués/Unicode)
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# ─── Couleurs / logging ──────────────────────────────────────────────────────
C_RESET=$'\033[0m'; C_GREEN=$'\033[1;32m'; C_RED=$'\033[1;31m'
C_YEL=$'\033[1;33m'; C_BLUE=$'\033[1;34m'

info() { printf "%s\n" "${C_BLUE}▶  $*${C_RESET}"; }
ok()   { printf "%s\n" "${C_GREEN}✅  $*${C_RESET}"; }
warn() { printf "%s\n" "${C_YEL}⚠️   $*${C_RESET}"; }
err()  { printf "%s\n" "${C_RED}❌  $*${C_RESET}"; }
step() { printf "\n%s\n" "${C_BLUE}━━━ $* ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"; }

FAILURES=()
fail() { err "$*"; FAILURES+=("$*"); }

# ─── Garde-fous ──────────────────────────────────────────────────────────────
if [[ "$(uname -s)" != "Darwin" ]]; then
  err "Ce script est destiné à macOS uniquement."; exit 1
fi
if [[ $EUID -eq 0 ]]; then
  err "Ne lancez PAS ce script avec sudo. Homebrew refuse l'installation en root."
  err "Relancez simplement : ./mac-setup.sh"
  exit 1
fi

# ─── Détection de l'architecture / préfixe Homebrew ──────────────────────────
if [[ "$(uname -m)" == "arm64" ]]; then
  BREW_PREFIX="/opt/homebrew"        # Apple Silicon
else
  BREW_PREFIX="/usr/local"           # Intel
fi
BREW_BIN="${BREW_PREFIX}/bin/brew"
ZPROFILE="$HOME/.zprofile"

# Listes (faciles à éditer)
FORMULAE=(zsh-autosuggestions zsh-syntax-highlighting eza fzf starship fastfetch)
CASKS=(brave-browser cleanshot linearmouse capacities proton-mail \
       rectangle visual-studio-code claude comet citrix-workspace)
# citrix-workspace : installeur .pkg → demande le mot de passe admin pendant l'install.
# Note : "claude" = Claude Desktop, qui embarque Cowork (pas de cask séparé).
# "comet" = navigateur Perplexity Comet.
# Correspondance cask -> nom du .app (pour la validation)
declare -a CASK_APPS=(
  "brave-browser|Brave Browser.app"
  "cleanshot|CleanShot X.app"
  "linearmouse|LinearMouse.app"
  "capacities|Capacities.app"
  "proton-mail|Proton Mail.app"
  "rectangle|Rectangle.app"
  "visual-studio-code|Visual Studio Code.app"
  "claude|Claude.app"
  "comet|Comet.app"
  "citrix-workspace|Citrix Workspace.app"
)

FONT_BASE="https://raw.githubusercontent.com/Karmenzind/monaco-nerd-fonts/master/fonts"
FONTS=(MonacoNerdFont-Regular.ttf MonacoNerdFontMono-Regular.ttf)
FONT_DIR="$HOME/Library/Fonts"

# =============================================================================
#  1. HOMEBREW
# =============================================================================
install_homebrew() {
  step "1/6 · Homebrew"
  if command -v brew &>/dev/null || [[ -x "$BREW_BIN" ]]; then
    ok "Homebrew déjà installé."
  else
    info "Installation de Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" \
      || { fail "Échec de l'installation de Homebrew."; return 1; }
  fi

  # shellenv dans ~/.zprofile (idempotent)
  local line="eval \"\$(${BREW_BIN} shellenv)\""
  touch "$ZPROFILE"
  if grep -qF "$line" "$ZPROFILE"; then
    ok "shellenv déjà présent dans ~/.zprofile."
  else
    { echo ""; echo "$line"; } >> "$ZPROFILE"
    ok "shellenv ajouté à ~/.zprofile."
  fi

  # Activation pour la session courante
  eval "$(${BREW_BIN} shellenv)"

  if command -v brew &>/dev/null; then
    ok "brew opérationnel ($(brew --version | head -1))."
  else
    fail "brew introuvable dans le PATH après installation."
  fi
}

# =============================================================================
#  2. FORMULES + 3. APPLICATIONS (casks)
# =============================================================================
install_packages() {
  step "2-3/6 · Formules & Applications"
  command -v brew &>/dev/null || { fail "Homebrew indisponible, packages ignorés."; return 1; }

  info "Mise à jour de Homebrew..."
  brew update --quiet || warn "brew update a renvoyé une erreur (non bloquant)."

  info "Installation des formules : ${FORMULAE[*]}"
  brew install "${FORMULAE[@]}" || warn "Une ou plusieurs formules ont échoué (vérif. ci-dessous)."

  # Installation cask par cask : un échec n'interrompt pas les suivants.
  # --adopt : adopte une app déjà présente dans /Applications (ex. Claude.app
  #           installé manuellement) au lieu de lever une erreur "already exists".
  info "Installation des applications (une par une) : ${CASKS[*]}"
  for cask in "${CASKS[@]}"; do
    if brew install --cask --adopt "$cask"; then
      ok "Cask OK : $cask"
    else
      warn "Cask à vérifier : $cask"
    fi
  done
}

# =============================================================================
#  4. POLICE — Monaco Nerd Font
# =============================================================================
install_font() {
  step "4/6 · Police Monaco Nerd Font"
  mkdir -p "$FONT_DIR"
  for f in "${FONTS[@]}"; do
    info "Téléchargement de ${f}..."
    if curl -fsSL "${FONT_BASE}/${f}" -o "${FONT_DIR}/${f}"; then
      ok "$f → ~/Library/Fonts/"
    else
      fail "Échec du téléchargement de la police $f."
    fi
  done
  # Pas de fc-cache sur macOS : détection automatique.
  ok "Police prête. À sélectionner dans le terminal : « Monaco Nerd Font Mono »."
}

# =============================================================================
#  5. SHELL — oh-my-zsh + starship.toml + .zshrc
# =============================================================================
install_ohmyzsh() {
  step "5/6 · oh-my-zsh + configuration ZSH"
  if [[ -d "$HOME/.oh-my-zsh" ]]; then
    ok "oh-my-zsh déjà installé."
  else
    info "Installation de oh-my-zsh (mode silencieux, sans toucher au .zshrc)..."
    # KEEP_ZSHRC=yes : on écrit NOTRE .zshrc juste après
    RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
      sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" \
      || fail "Échec de l'installation de oh-my-zsh."
  fi

  # ── starship.toml ──────────────────────────────────────────────────────────
  mkdir -p "$HOME/.config"
  [[ -f "$HOME/.config/starship.toml" ]] && \
    cp "$HOME/.config/starship.toml" "$HOME/.config/starship.toml.bak.$(date +%Y%m%d%H%M%S)" && \
    info "Ancien starship.toml sauvegardé."

  cat > "$HOME/.config/starship.toml" <<'STARSHIP'
"$schema" = 'https://starship.rs/config-schema.json'

format = """
[╭─](bold green)$os$username$hostname$directory$git_branch$git_status$python$nodejs$rust$golang$docker_context
[╰─](bold green)$character"""

[os]
disabled = false
style = "bold blue"

[os.symbols]
Ubuntu = " "
Macos = "󰀵 "

[username]
show_always = true
style_user = "bold cyan"
style_root = "bold red"
format = "[$user]($style)"

[hostname]
ssh_only = false
format = "@[$hostname](bold yellow) "
disabled = false

[directory]
style = "bold cyan"
truncation_length = 4
truncate_to_repo = true
format = "in [$path]($style)[$read_only]($read_only_style) "

[git_branch]
symbol = " "
style = "bold purple"
format = "on [$symbol$branch]($style) "

[git_status]
format = '([\[$all_status$ahead_behind\]]($style) )'
style = "bold red"

[character]
success_symbol = "[❯](bold green)"
error_symbol = "[❯](bold red)"
vimcmd_symbol = "[❮](bold green)"

[python]
symbol = " "
format = 'via [$symbol$version]($style) '

[conda]
symbol = " "
format = 'via [$symbol$environment]($style) '

[nodejs]
symbol = " "

[docker_context]
symbol = " "
format = "via [$symbol$context]($style) "
STARSHIP
  ok "~/.config/starship.toml écrit."

  # ── .zshrc ───────────────────────────────────────────────────────────────
  [[ -f "$HOME/.zshrc" ]] && \
    cp "$HOME/.zshrc" "$HOME/.zshrc.bak.$(date +%Y%m%d%H%M%S)" && \
    info "Ancien .zshrc sauvegardé."

  # Heredoc QUOTÉ ('ZSHRC') : aucune variable n'est expansée à l'écriture,
  # tout est évalué au runtime par zsh.
  cat > "$HOME/.zshrc" <<'ZSHRC'
export ZSH="$HOME/.oh-my-zsh"
# ─── Prompt — Starship ────────────────────────────────────────────────────────
ZSH_THEME=""   # désactivé, Starship prend le relai
# ─── oh-my-zsh settings ───────────────────────────────────────────────────────
zstyle ':omz:update' mode reminder
ENABLE_CORRECTION="true"
COMPLETION_WAITING_DOTS="true"
# ─── Plugins ──────────────────────────────────────────────────────────────────
# zsh-syntax-highlighting DOIT être en dernier
plugins=(
    git
    fzf
    vscode
    z
)
source $ZSH/oh-my-zsh.sh
# ─── Starship ─────────────────────────────────────────────────────────────────
eval "$(starship init zsh)"
# ─── zsh-autosuggestions (Homebrew) ───────────────────────────────────────────
source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#888888"
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
bindkey '→' autosuggest-accept
# ─── zsh-syntax-highlighting (Homebrew) ───────────────────────────────────────
source $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
# ─── Editor ───────────────────────────────────────────────────────────────────
if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='nvim'
else
  export EDITOR='nano'
fi
# ─── PATH ─────────────────────────────────────────────────────────────────────
export PATH=$HOME/bin:/usr/local/bin:$PATH
# ─── Navigation ───────────────────────────────────────────────────────────────
alias ..='cd ..'
alias ...='cd ../..'
alias .3='cd ../../..'
alias .4='cd ../../../..'
alias .5='cd ../../../../..'
# ─── Editors ──────────────────────────────────────────────────────────────────
alias vim='nvim'
# ─── ls → eza ─────────────────────────────────────────────────────────────────
unalias ls la ll lt 2>/dev/null
alias ls='eza -al --color=always --group-directories-first --icons'
alias la='eza -a --color=always --group-directories-first --icons'
alias ll='eza -l --color=always --group-directories-first --icons'
alias lt='eza -aT --color=always --group-directories-first --icons'
alias l.='eza -a | grep -E "^\."'
# ─── Homebrew ─────────────────────────────────────────────────────────────────
alias bud='brew update'
alias bug='brew upgrade'
alias bcu='brew cleanup && brew autoremove'
alias upcheck='brew update'
alias upall='brew upgrade'
alias cleanup='brew cleanup && brew autoremove'
# ─── grep colorisé ────────────────────────────────────────────────────────────
alias grep='grep --color=auto'
alias egrep='egrep --color=auto'
alias fgrep='fgrep --color=auto'
# ─── Sécurité ─────────────────────────────────────────────────────────────────
alias cp='cp -iv'
alias mv='mv -iv'
alias rm='rm -iv'
alias df='df -h'
alias du='du -h'
alias free='top -l 1 | grep PhysMem'
# ─── macOS utils ──────────────────────────────────────────────────────────────
alias flushdns='sudo dscacheutil -flushcache && sudo killall -HUP mDNSResponder'
alias showfiles='defaults write com.apple.finder AppleShowAllFiles YES && killall Finder'
alias hidefiles='defaults write com.apple.finder AppleShowAllFiles NO && killall Finder'
# ─── Git ──────────────────────────────────────────────────────────────────────
alias g='git'
alias gs='git status'
alias ga='git add'
alias addup='git add -u'
alias addall='git add .'
alias branch='git branch'
alias checkout='git checkout'
alias clone='git clone'
alias commit='git commit -m'
alias fetch='git fetch'
alias pull='git pull origin'
alias push='git push origin'
alias tag='git tag'
alias newtag='git tag -a'
alias gl='git log --oneline --graph --decorate'
# ─── fzf ──────────────────────────────────────────────────────────────────────
export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border --info=inline'
# ─── Conda ────────────────────────────────────────────────────────────────────
__conda_setup="$('/opt/homebrew/Caskroom/miniconda/base/bin/conda' 'shell.zsh' 'hook' 2>/dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
elif [ -f "/opt/homebrew/Caskroom/miniconda/base/etc/profile.d/conda.sh" ]; then
    source "/opt/homebrew/Caskroom/miniconda/base/etc/profile.d/conda.sh"
else
    export PATH="/opt/homebrew/Caskroom/miniconda/base/bin:$PATH"
fi
unset __conda_setup
# ─── Mole completion ──────────────────────────────────────────────────────────
if output="$(mole completion zsh 2>/dev/null)"; then eval "$output"; fi
# ─── Démarrage ────────────────────────────────────────────────────────────────
command -v fastfetch &>/dev/null && fastfetch
# ─── Pour les connexions ssh ─────────────────────────────────────────────────────
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
ZSHRC
  ok "~/.zshrc écrit (fastfetch protégé par un garde 'command -v')."
}

# =============================================================================
#  6. BRAVE — Debloat via Managed Preferences policy
# =============================================================================
apply_brave_policies() {
  step "6/6 · Policies Brave (debloat)"
  local app="Brave Browser"
  local plist="/Library/Managed Preferences/com.brave.Browser.plist"

  # Fermer Brave (en tant qu'utilisateur) pour qu'il recharge les policies
  if pgrep -x "$app" &>/dev/null; then
    info "Fermeture de Brave..."
    osascript -e "quit app \"$app\"" 2>/dev/null
    sleep 2
    pkill -x "$app" 2>/dev/null
  fi

  # Réglage user-level : background mode OFF (pas besoin de root)
  defaults write com.brave.Browser BackgroundModeEnabled -bool false 2>/dev/null \
    && ok "BackgroundModeEnabled = false (préférence utilisateur)."

  # Dossier de téléchargement par défaut : ~/Downloads
  local dldir="$HOME/Downloads"
  mkdir -p "$dldir"
  ok "Dossier de téléchargement garanti : $dldir"

  info "Écriture des policies (mot de passe administrateur requis)..."
  sudo -v || { fail "Authentification sudo refusée — policies Brave ignorées."; return 1; }

  # DLDIR est transmis à l'environnement root par sudo (il est résolu côté
  # utilisateur ; sous root, $HOME pointerait vers /var/root).
  sudo DLDIR="$dldir" bash <<'SUDO_EOF'
set -e
PLIST_DIR="/Library/Managed Preferences"
PLIST="$PLIST_DIR/com.brave.Browser.plist"

# 1) S'assurer que le dossier existe EN AMONT (avant toute écriture)
mkdir -p "$PLIST_DIR"

# 2) Écrire le fichier de policy DIRECTEMENT en XML.
#    NB : on n'utilise PAS `defaults write` ici car /Library/Managed Preferences
#    est géré par cfprefsd : l'écriture partirait dans un cache et le fichier
#    physique ne serait jamais créé. Un cat > … garantit sa présence.
#    Heredoc NON quoté (PLIST_XML) pour que $DLDIR soit substitué.
cat > "$PLIST" <<PLIST_XML
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>BraveAIChatEnabled</key>        <false/>
    <key>BraveNewsDisabled</key>         <true/>
    <key>BravePlaylistEnabled</key>      <false/>
    <key>BraveRewardsDisabled</key>      <true/>
    <key>BraveSpeedreaderEnabled</key>   <false/>
    <key>BraveP3AEnabled</key>           <false/>
    <key>BraveStatsPingEnabled</key>     <false/>
    <key>BraveTalkDisabled</key>         <true/>
    <key>TorDisabled</key>               <true/>
    <key>BraveVPNDisabled</key>          <true/>
    <key>BraveWalletDisabled</key>       <true/>
    <key>BraveWaybackMachineEnabled</key> <false/>
    <key>BraveWebDiscoveryEnabled</key>  <false/>
    <key>SyncDisabled</key>              <false/>
    <key>DownloadDirectory</key>         <string>$DLDIR</string>
    <key>PromptForDownloadLocation</key> <false/>
</dict>
</plist>
PLIST_XML

# 3) Valider la syntaxe du plist (échoue proprement si XML invalide)
/usr/bin/plutil -lint "$PLIST"

# 4) Permissions correctes
/bin/chmod 644 "$PLIST"
/usr/sbin/chown root:wheel "$PLIST"
SUDO_EOF

  if [[ $? -eq 0 && -f "$plist" ]]; then
    ok "Policies Brave appliquées dans /Library/Managed Preferences/."
  else
    fail "Échec de l'application des policies Brave."
  fi
}

# =============================================================================
#  VALIDATION FINALE
# =============================================================================
validate() {
  step "Validation"

  # Homebrew
  command -v brew &>/dev/null && ok "Homebrew présent" || fail "Homebrew manquant"

  # Formules
  local installed; installed="$(brew list --formula 2>/dev/null)"
  for f in "${FORMULAE[@]}"; do
    if grep -qx "$f" <<<"$installed"; then ok "Formule : $f"; else fail "Formule manquante : $f"; fi
  done

  # Applications
  for pair in "${CASK_APPS[@]}"; do
    local appname="${pair#*|}"
    if [[ -d "/Applications/${appname}" || -d "$HOME/Applications/${appname}" ]]; then
      ok "App : ${appname}"
    else
      fail "App manquante : ${appname}"
    fi
  done

  # Police
  for f in "${FONTS[@]}"; do
    [[ -f "${FONT_DIR}/${f}" ]] && ok "Police : $f" || fail "Police manquante : $f"
  done

  # Shell
  [[ -d "$HOME/.oh-my-zsh" ]] && ok "oh-my-zsh installé" || fail "oh-my-zsh manquant"
  [[ -f "$HOME/.config/starship.toml" ]] && ok "starship.toml présent" || fail "starship.toml manquant"
  if [[ -f "$HOME/.zshrc" ]] && grep -q "starship init zsh" "$HOME/.zshrc"; then
    ok ".zshrc configuré (Starship)"
  else
    fail ".zshrc non configuré"
  fi
  grep -qF "brew shellenv" "$ZPROFILE" 2>/dev/null && ok ".zprofile : shellenv OK" || fail ".zprofile : shellenv manquant"

  # Brave policy
  [[ -f "/Library/Managed Preferences/com.brave.Browser.plist" ]] \
    && ok "Policy Brave présente" || fail "Policy Brave manquante"
}

# =============================================================================
#  MAIN
# =============================================================================
printf "%s\n" "${C_GREEN}"
cat <<'BANNER'
  ┌─────────────────────────────────────────────┐
  │        macOS — Setup automatisé               │
  │   Homebrew · Apps · Font · ZSH · Brave        │
  └─────────────────────────────────────────────┘
BANNER
printf "%s\n" "${C_RESET}"
info "Cible Homebrew : ${BREW_PREFIX}   (arch : $(uname -m))"

install_homebrew
install_packages
install_font
install_ohmyzsh
apply_brave_policies
validate

# ─── Récapitulatif ───────────────────────────────────────────────────────────
step "Récapitulatif"
if [[ ${#FAILURES[@]} -eq 0 ]]; then
  ok "Toutes les étapes ont été validées avec succès. 🎉"
else
  err "${#FAILURES[@]} élément(s) à vérifier :"
  for f in "${FAILURES[@]}"; do printf "   %s- %s%s\n" "$C_RED" "$f" "$C_RESET"; done
fi

cat <<'NEXT'

────────────────────────────────────────────────────────────────────────
 ÉTAPES MANUELLES RESTANTES
────────────────────────────────────────────────────────────────────────
 1. Recharger le shell :   exec zsh      (ou ouvrir un nouvel onglet)
 2. Terminal → Préférences → Police :  « Monaco Nerd Font Mono »
 3. Lancer Brave puis ouvrir  brave://policy
    → toutes les clés doivent être : source « Platform », niveau « Mandatory »
 4. Brave, réglages manuels complémentaires (non scriptables via policy) :
      brave://settings/privacy
        • Diagnostic reports ........... OFF
        • Google push messaging ........ OFF
        • WebRTC IP handling ........... Disable non-proxied UDP
        • Auto-redirect AMP ............ ON
        • Auto-redirect tracking URLs .. ON
        • Fingerprinting via language .. ON
      Masquer dans l'UI (clic droit → Hide) : Wallet, Leo, cartes VPN/Talk
 5. Première ouverture des apps : autoriser dans
    Réglages Système → Confidentialité & sécurité (Gatekeeper).
    LinearMouse & CleanShot demanderont Accessibilité / Enregistrement d'écran.
────────────────────────────────────────────────────────────────────────
NEXT
