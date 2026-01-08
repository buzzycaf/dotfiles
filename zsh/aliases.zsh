# Aliases
alias ls='ls --color'
alias cls='clear'

# Safer defaults
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'
alias ll='ls -lah'

# Navigation
alias ..='cd ..'
alias ...='cd ../..'

# Git
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline --graph --decorate'

# System
alias df='df -h'
alias du='du -h'

# TMUX
alias t='tmux'
alias ta='tmux attach -t'
alias tl='tmux ls'
alias tn='tmux new -s'

# View image
img() {
  setsid swayimg "$@" >/dev/null 2>&1 &
}
