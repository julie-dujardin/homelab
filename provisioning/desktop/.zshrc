# Keybindings - linux only
bindkey '^H' backward-kill-word # Ctrl+Backspace - delete word backward
bindkey '^[[3;5~' kill-word # Ctrl+Delete - delete word forward

# Increase history size
export HISTSIZE=50000
export SAVEHIST=$HISTSIZE
setopt hist_ignore_all_dups
