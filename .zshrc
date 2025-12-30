export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="funky"

ENABLE_CORRECTION="true"

COMPLETION_WAITING_DOTS="true"

plugins=(
        git
        fzf
        macos
        vscode
        z
        zsh-autocomplete
        zsh-syntax-highlighting
        zsh-autosuggestions
)

source $ZSH/oh-my-zsh.sh

if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='nvim'
else
  export EDITOR='nano'
fi

# User configuration

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes.
alias ..='cd ..'
alias ...='cd ../..'
alias .3='cd ../../..'
alias .4='cd ../../../..'
alias .5='cd ../../../../..'

# vim and emacs
alias vim='nvim'

# Changing "ls" to "eza"
alias ls='eza -al --color=always --group-directories-first'
alias la='eza -a --color=always --group-directories-first'
alias ll='eza -l --color=always --group-directories-first'
alias lt='eza -aT --color=always --group-directories-first'
alias l.='eza -a | egrep "^\."'

# rpm-ostree
alias upall='sudo dnf update && sudo dnf upgrade -y'
alias upcheck='sudo dnf check-update'

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

# git
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

export PATH=$HOME/bin:/usr/local/bin:$PATH

# system reporting
fastfetch
