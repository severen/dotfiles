# Dotfiles

These are my personal configuration files and scripts, written primarily for
use on an Arch Linux system. In particular, I strive to minimise the amount of
files under `$HOME` by adhering to the [XDG standards][xdg] wherever possible.

## Quick Start

I manage my dotfiles with [Dotdrop][dotdrop] via the `dotdrop` script.

To install the dotfiles specified for the host, run `./dotdrop install`, which
will work so long as Python is available.

## Programs

If you are interested, these are the core programs I use at a glance:

* Shell: zsh
* Window Manager: bspwm
* Status Bar: Polybar
* Text Editor: Primarily Emacs, with Neovim for quick editing in the terminal.
* Browser: Chromium, although I am looking to use Qutebrowser.
* Image Viewer: sxiv
* Music Player: mpd and ncmpcpp
* Video Player: mpv

[dotdrop]: https://github.com/deadc0de6/dotdrop
[xdg]: https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html
