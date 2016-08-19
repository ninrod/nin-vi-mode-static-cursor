# terminal colors {{{

TC='\e['
Rst="${TC}0m"     # Reset all coloring and style
Black="${TC}30m";
Red="${TC}31m";
Green="${TC}32m";
Yellow="${TC}33m";
Blue="${TC}34m";
Purple="${TC}35m";
Cyan="${TC}36m";
White="${TC}37m";

# }}}
# bootstrap, keymap-select and cursor shape management {{{

# manage cursor shape under different keymaps on iTerm2
function zle-keymap-select() {
  zle reset-prompt
  zle -R
}
zle -N zle-keymap-select

# when we cancel the current command, return the cursor shape to block
TRAPINT() {
  print -n " ${Purple}[${Cyan}ctrl-c${Purple}]${Rst}"
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

# can safely disable this after commit zsh commit #a73ae70 (zsh-5.2-301-ga73ae70)
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
