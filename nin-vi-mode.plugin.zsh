# no delays for mode switching.{{{

export KEYTIMEOUT=15

# }}}
# zle-keymap-select and bootstrap: Updates editor information when the keymap changes {{{

# for the mintty terminal
function zle-keymap-select() {
  if [[ -n ${TMUX+x} ]]; then
    if [[ $KEYMAP = vicmd ]]; then
      # the command mode for vi: block shape
      echo -ne "\ePtmux;\e\e[2 q\e\\"
    else
      # the insert mode for vi: line shape
      echo -ne "\ePtmux;\e\e[6 q\e\\"
    fi
  elif [[ $KEYMAP = vicmd ]]; then
    # the command mode for vi: block shape
    echo -ne "\e[2 q"
  else
    # the insert mode for vi: line shape
    echo -ne "\e[6 q"
  fi
  zle reset-prompt
  zle -R
}

# Ensure that the prompt is redrawn when the terminal size changes.
TRAPWINCH() {
  zle && { zle reset-prompt; zle -R }
}

zle -N zle-keymap-select

bindkey -v

# }}}
# text objects support {{{
# since zsh 5.0.8, text objects were introduced. Let's use some of them.
# see here for more info: http://www.zsh.org/mla/workers/2015/msg01017.html
# and here: https://github.com/zsh-users/zsh/commit/d257f0143e69c3724466c4c92f59538d2f3fffd1

# using select-bracketed as intructed on: https://github.com/zsh-users/zsh/blob/master/Functions/Zle/select-bracketed#L6
# same as vim c+motion (change inside/around text-object).
autoload -U select-bracketed
zle -N select-bracketed
for m in visual viopp; do
  for c in {a,i}${(s..)^:-'()[]{}<>bB'}; do
    bindkey -M $m $c select-bracketed
  done
done

# using select-quoted as instructed on: https://github.com/zsh-users/zsh/blob/master/Functions/Zle/select-quoted#L6
# expands c+motion (change inside/around + text-object) to quotes.
autoload -U select-quoted
zle -N select-quoted
for m in visual viopp; do
  for c in {a,i}{\',\",\`}; do
    bindkey -M $m $c select-quoted
  done
done

# add support for the surround plugin emulation widget
# due to KEYTIMEOUT set to a low number, you have to press the chords very, very fast.
autoload -Uz surround
zle -N delete-surround surround
zle -N add-surround surround
zle -N change-surround surround
bindkey -a cs change-surround
bindkey -a ds delete-surround
bindkey -a ys add-surround
bindkey -M visual S add-surround

# }}}
# simple binds {{{

autoload -Uz edit-command-line
zle -N edit-command-line
bindkey -M vicmd 'gs' edit-command-line

bindkey -M vicmd '?' history-incremental-search-backward

bindkey -M visual 'Q' quote-region

# }}}
# my custom widgets {{{

# pressing <ESC> in normal mode is bogus: you need to press 'i' twice to enter insert mode again.
# rebinding <ESC> in normal mode to something harmless solves the problem.
nin-noop(){}
zle -N nin-noop
bindkey -M vicmd '\e' nin-noop

# bindkey -M visual 'S' quote-region

# credits go to Oliver Kiddle <opk@zsh.org>,
# who personally shared these upper/lower widgets.
# I just corrected a small bug.
vi-lowercase() {
  local save_cut="$CUTBUFFER"
  local save_cur="$CURSOR"

  zle .vi-change || return
  zle .vi-cmd-mode

  CUTBUFFER="${CUTBUFFER:l}"

  if [[ $CURSOR = '0' ]]; then
    zle .vi-put-before -n 1
  else
    zle .vi-put-after -n 1
  fi

  CUTBUFFER="$save_cut" 
  CURSOR="$save_cur"
}

vi-uppercase() {
  local save_cut="$CUTBUFFER" 
  local save_cur="$CURSOR"

  zle .vi-change || return
  zle .vi-cmd-mode

  CUTBUFFER="${CUTBUFFER:u}"

  if [[ $CURSOR = '0' ]]; then
    zle .vi-put-before -n 1
  else
    zle .vi-put-after -n 1
  fi

  CUTBUFFER="$save_cut" 
  CURSOR="$save_cur"
}

zle -N vi-lowercase
zle -N vi-uppercase

bindkey -a 'gU' vi-uppercase
bindkey -a 'gu' vi-lowercase
bindkey -M visual 'u' vi-lowercase
bindkey -M visual 'U' vi-uppercase

# }}}
# various escape code fixes {{{

# home, end, delete and backspace
bindkey "^[[1~" beginning-of-line # home key
bindkey "^[[4~" end-of-line # end key
bindkey "^[[3~" delete-char # delete key
bindkey "^H" backward-delete-char # backspace key
bindkey "^?" backward-delete-char # backspace key

# Numeric Keypad fixes
bindkey "${terminfo[kent]}" accept-line # numeric keypad return (enter)
bindkey -s "^[Op" "0"
bindkey -s "^[On" "."
bindkey -s "^[Oq" "1"
bindkey -s "^[Or" "2"
bindkey -s "^[Os" "3"
bindkey -s "^[Ot" "4"
bindkey -s "^[Ou" "5"
bindkey -s "^[Ov" "6"
bindkey -s "^[Ow" "7"
bindkey -s "^[Ox" "8"
bindkey -s "^[Oy" "9"
bindkey -s "^[Ol" "+"
bindkey -s "^[OS" "-"
bindkey -s "^[OR" "*"
bindkey -s "^[OQ" "/"

# }}}
