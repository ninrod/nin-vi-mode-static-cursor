# helper functions {{{

# nin-cursor-shape: Change the cursor shape under iTerm2
# escape sequence: `^[]1337;CursorShape=N^G`. N=1, vertical line, N=0, block.
# ^G = \x7
# ˆ[ = \e
# Tmux escape sequence example: "\ePtmux;\e\e]1337;CursorShape=1\x7\e\\"
# Normal shell escape sequence example: "\e]1337;CursorShape=1\x7"
# more info here://www.iterm2.com/documentation-escape-codes.html
nin-cursor-shape() {
  local tmuxescape="\ePtmux;\e\e]1337;CursorShape=${1}\x7\e\\"
  local normalescape="\e]1337;CursorShape=${1}\x7"
  if [[ -n ${TMUX+x} ]]; then
    echo -ne $tmuxescape
  else
    echo -ne $normalescape
  fi
}

# }}}
# bootstrap, keymap-select and cursor shape management {{{

# Oliver Kiddle <opk@zsh.org> optimization:
# If you change the cursor shape, consider taking care to reset it when
# not in ZLE. zle-line-finish is only run when ZLE is succcessful so the
# best place for the reset is in POSTEDIT:
POSTEDIT+=$'\e]1337;CursorShape=0\x7'

# manage cursor shape under different keymaps
function zle-keymap-select() {
  if [[ $KEYMAP = vicmd ]]; then
    nin-cursor-shape 0
  elif [[ $KEYMAP = main ]]; then
    nin-cursor-shape 1
  fi
  # reset prompt if you use keymap mode indication
  # zle reset-prompt
  zle -R
}
zle -N zle-keymap-select

# when we hit <cr> return cursor shape to block
nin-accept-line() {
  nin-cursor-shape 0
  zle .accept-line
}
zle -N nin-accept-line
# ^J and ^M are the same as <cr>
bindkey "^@" nin-accept-line
bindkey "^J" nin-accept-line
bindkey "^M" nin-accept-line

# when we cancel the current command, return the cursor shape to block
TRAPINT() {
  nin-cursor-shape 0
  return $(( 128 + $1 ))
}

# Ensure that the prompt is redrawn when the terminal size changes.
TRAPWINCH() {
  zle && { zle reset-prompt; zle -R }
}

# no delays when switching keymaps
export KEYTIMEOUT=5
# bootstrap vi-mode
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
