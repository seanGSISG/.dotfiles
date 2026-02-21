# Terminal keybindings
# Emacs mode with enhanced navigation

# Emacs mode
bindkey -e

# Ctrl+Arrow for word movement
bindkey "^[[1;5C" forward-word
bindkey "^[[1;5D" backward-word

# Alt+Arrow for word movement
bindkey "^[[1;3C" forward-word
bindkey "^[[1;3D" backward-word
bindkey "^[^[[C" forward-word
bindkey "^[^[[D" backward-word

# Ctrl+Backspace and Ctrl+Delete
bindkey "^H" backward-kill-word
bindkey "^[[3;5~" kill-word

# Home/End keys (multiple escape code variants)
bindkey "^[[H" beginning-of-line
bindkey "^[[F" end-of-line
bindkey "^[[1~" beginning-of-line
bindkey "^[[4~" end-of-line
