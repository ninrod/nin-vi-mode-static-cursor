# no delays for mode switching.
export KEYTIMEOUT=1

# Updates editor information when the keymap changes.
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

# for the mintty terminal
# function zle-keymap-select() {
#   if [[ -n ${TMUX+x} ]]; then
#     if [[ $KEYMAP = vicmd ]]; then
#       # the command mode for vi: block shape
#       echo -ne "\ePtmux;\e\e[2 q\e\\"
#     else
#       # the insert mode for vi: line shape
#       echo -ne "\ePtmux;\e\e[6 q\e\\"
#     fi
#   elif [[ $KEYMAP = vicmd ]]; then
#     # the command mode for vi: block shape
#     echo -ne "\e[2 q"
#   else
#     # the insert mode for vi: line shape
#     echo -ne "\e[6 q"
#   fi
#   zle reset-prompt
#   zle -R
# }

# Ensure that the prompt is redrawn when the terminal size changes.
TRAPWINCH() {
  zle && { zle reset-prompt; zle -R }
}

zle -N zle-keymap-select

bindkey -v

# edit line with vim
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey -M vicmd 'gs' edit-command-line

bindkey -M vicmd '?' history-incremental-search-backward

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

############# zsh escape code fixes #############

# home key
bindkey "^[[1~" beginning-of-line

# end key
bindkey "^[[4~" end-of-line

# delete key
bindkey "^[[3~" delete-char

# backspace key
bindkey "^H" backward-delete-char
bindkey "^?" backward-delete-char

# numeric keypad return (enter)
bindkey "${terminfo[kent]}" accept-line

# pressing <ESC> in normal mode is bogus: you need to press 'i' twice to enter insert mode again.
# rebinding <ESC> in normal mode to something harmless solves the problem.
# nin-noop(){}
# zle -N nin-noop
# bindkey -M vicmd '\e' nin-noop

# from zsh mailing lists: (my question)
# As presently implemented, visual mode is a combination of a couple of different
# states that can each be changed independently; the determination of
# whether this "mode" is in effect is not made until the last instant
# before ZLE waits for the next keystroke, and is forgotten as soon as
# the keystroke has been consumed.  The keymap isn't even in place long
# enough for the corresponding widget to see it; it's indistinguishable
# from vicmd mode.
# ------------
# pressing <ESC> in visual mode should return zle to normal mode
# a deactivate-region widget was added in 5.1 so this is for zsh 5.0.8
nin-deactivate-region() {
	REGION_ACTIVE=0
}
zle -N nin-deactivate-region
bindkey -M visual '\e' nin-deactivate-region

bindkey -M visual 'S' quote-region

vi-lowercase() {
  local save_cut="$CUTBUFFER" 
  local save_cur="$CURSOR"

  zle .vi-change || return
  zle .vi-cmd-mode

  CUTBUFFER="${CUTBUFFER:l}"

  if [[ $save_cur = '1' ]]; then
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

  if [[ $save_cur = '1' ]]; then
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

# Keypad fixes
# 0 .
bindkey -s "^[Op" "0"
bindkey -s "^[On" "."
# 1 2 3
bindkey -s "^[Oq" "1"
bindkey -s "^[Or" "2"
bindkey -s "^[Os" "3"
# 4 5 6
bindkey -s "^[Ot" "4"
bindkey -s "^[Ou" "5"
bindkey -s "^[Ov" "6"
# 7 8 9
bindkey -s "^[Ow" "7"
bindkey -s "^[Ox" "8"
bindkey -s "^[Oy" "9"
# + -  * /
bindkey -s "^[Ol" "+"
bindkey -s "^[OS" "-"
bindkey -s "^[OR" "*"
bindkey -s "^[OQ" "/"

########### vi-like copy and paste on OSx ##########
if [ `uname` = "Darwin" ] && (($+commands[pbcopy])); then
  function cutbuffer() {
    zle .$WIDGET
    echo $CUTBUFFER | pbcopy
  }

  zle_cut_widgets=(
    vi-backward-delete-char
    vi-change
    vi-change-eol
    vi-change-whole-line
    vi-delete
    vi-delete-char
    vi-kill-eol
    vi-substitute
    vi-yank
    vi-yank-eol
  )
  for widget in $zle_cut_widgets
  do
    zle -N $widget cutbuffer
  done

  function putbuffer() {
    zle copy-region-as-kill "$(pbpaste)"
    zle .$WIDGET
  }

  zle_put_widgets=(
    vi-put-after
    vi-put-before
  )
  for widget in $zle_put_widgets
  do
    zle -N $widget putbuffer
  done
fi
