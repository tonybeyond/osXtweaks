# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# ZSH_THEME="agnoster"
ZSH_THEME=""

export ZPLUG_HOME=$(brew --prefix)/opt/zplug
source $ZPLUG_HOME/init.zsh
zplug "mafredri/zsh-async", from:github
zplug "sindresorhus/pure", use:pure.zsh, from:github, as:theme
zplug load
# Install plugins if there are plugins that have not been installed
if ! zplug check --verbose; then
    printf "Install? [y/N]: "
    if read -q; then
        echo; zplug install
    fi
fi

plugins=(git vscode fzf macos zsh-autocomplete zsh-syntax-highlighting zsh-autosuggestions)

source $ZSH/oh-my-zsh.sh

#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"
# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes.
alias ..='cd ..'
alias ...='cd ../..'
alias .3='cd ../../..'
alias .4='cd ../../../..'
alias .5='cd ../../../../..'

# vim and emacs
alias vim='nvim'

# Changing "ls" to "exa"
alias ls='eza -al --color=always --group-directories-first'
alias la='eza -a --color=always --group-directories-first'
alias ll='eza -l --color=always --group-directories-first'
alias lt='eza -aT --color=always --group-directories-first'
alias l.='eza -a | egrep "^\."'

# Colorize grep output
alias grep='grep --color=auto'
alias egrep='egrep --color=auto'
alias fgrep='fgrep --color=auto'

# confirm before overwriting something
alias cp="cp -i"
alias mv='mv -i'
alias rm='rm -i'

# adding flags
alias df='df -h'

# brew
alias bud='brew update'
alias bug='brew upgrade'
alias bcu='brew cleanup'

# system reporting
hyfetch

# Created by `pipx` on 2024-06-10 13:41:15
export PATH="$PATH:/Users/machy/.local/bin"
export PATH="$PATH:/Users/machy/go/bin/"

# personal fabric aliaes
alias ytsum='function _ytsummarize() { fabric -y "$1" --stream --pattern youtube_summary | glow; }; _ytsummarize'
alias ytbase='function _ytsummarize() { fabric -y "$1"; }; _ytsummarize'
alias claims='pbpaste | fabric --stream --pattern analyze_claims | glow'
alias summarize='pbpaste  | fabric --stream --pattern summarize -g=fr | glow'
fpath=(~/.zsh/completions $fpath)
autoload -Uz compinit && compinit
