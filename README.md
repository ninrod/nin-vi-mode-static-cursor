# NIN-VI-MODE

This plugin increases ZLE, the zsh line editor, `vi-like` capabilities.

## Usage

Type a word, `<esc>`, and `gUiw`. Yes, it works.

## Install

Recommended method: [zplug](http://github.com/zplug/zplug). just add this to your `.zshrc`:

```sh
zplug "ninrod/nin-vi-mode"
```

## Mode indicators

I provide none. I find it too distracting. The only indicator you'll have will be the cursor shape.

It's a block in normal mode and a line shape in insert mode.

## Vim edition: for when things get hairy

I've bound normal mode `gs` to fire up `vim` so you can edit your command with full vimmic powers.
