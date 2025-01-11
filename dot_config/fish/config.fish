# Override the value set by bash prior to exec'ing fish.
set -x SHELL (command -s fish)

# This is an (ongoing) attempt to wrangle misbehaving programs into (somewhat)
# complying with the XDG base directories standard. A lot of these environment
# variables simply move the program's catch-all directories from $HOME to
# $XDG_DATA_HOME, which while not _entirely_ standards compliant, at least
# cleans up $HOME.
set -gx RUSTUP_HOME "$XDG_DATA_HOME/rustup"
set -gx CARGO_HOME "$XDG_DATA_HOME/cargo"
set -gx GHCUP_USE_XDG_DIRS "yes"
set -gx STACK_ROOT "$XDG_DATA_HOME/stack"
set -gx MIX_XDG "true"
set -gx GRADLE_USER_HOME "$XDG_DATA_HOME/gradle"
set -gx GOPATH "$XDG_DATA_HOME/go"
set -gx GOMODCACHE "$XDG_CACHE_HOME/go/mod"
set -gx IPYTHONDIR "$XDG_CONFIG_HOME/jupyter"
set -gx PYLINTHOME "$XDG_CACHE_HOME/pylint"
set -gx TEXMFHOME "$XDG_DATA_HOME/texlive"
set -gx TEXMFCONFIG "$XDG_CONFIG_HOME/texlive"
set -gx TEXMFVAR "$XDG_CACHE_HOME/texlive"
set -gx GDBHISTORY "$XDG_DATA_HOME/gdb/history"
set -gx NODE_REPL_HISTORY "$XDG_DATA_HOME/node/history"
set -gx WGETRC "$XDG_CONFIG_HOME/wgetrc"
set -gx PARALLEL_HOME "$XDG_DATA_HOME/parallel"
set -gx GTK2_RC_FILES "$XDG_CONFIG_HOME/gtk-2.0/gtkrc"
# One could argue that this should be in $XDG_CONFIG_HOME, but as far as I can
# tell, these files are generated in a machine-specific way.
set -gx _JAVA_OPTIONS "-Djava.util.prefs.userRoot $XDG_DATA_HOME/java"

# Ruff uses a project local cache by default.
set -gx RUFF_CACHE_DIR "$XDG_CACHE_HOME/ruff"

set -gx EDITOR "nvim"
set -gx VISUAL $EDITOR
set -gx DIFFPROG "nvim -d"

# Prevent Go from automatically downloading a newer toolchain.
set -gx GOTOOLCHAIN "local"

# Set the QMK repository location.
set -gx QMK_HOME "$HOME/Documents/Code/qmk"

# Enable incremental search with smart case and decrease the tab size in less.
set -gx LESS "-R --incsearch --ignore-case --tabs 2"

if test $hostname != "yggdrasill"
  # Direct programs that expect a Docker daemon socket to Podman's compatible
  # stand-in.
  set -gx DOCKER_HOST "unix://$XDG_RUNTIME_DIR/podman/podman.sock"
else
  # On my work laptop, I use Docker instead of Podman. Because of code of ours
  # that relies on Docker Compose's old container naming scheme, the following
  # needs to be set to revert to the old scheme.
  set -gx COMPOSE_COMPATIBILITY 1

  set -gx GL_HOST "gitlab.sitehost.co.nz"
end

# This is not needed on GNOME as it includes its own SSH agent.
if test $XDG_SESSION_DESKTOP; and test $XDG_SESSION_DESKTOP != "gnome"
  # Wire up the SSH agent for persisting SSH credentials.
  set -gx SSH_AUTH_SOCK "$XDG_RUNTIME_DIR/ssh-agent.socket"
end

if test $XDG_SESSION_TYPE; test $XDG_SESSION_TYPE = "wayland"
  # Force GTK 3 and 4 to use a file dialog (and other things) that is native to
  # the current desktop environment. Note that this doesn't necessarily mean
  # that a GTK application will use native file dialogs unless it uses the
  # FileChooserNative API (or FileDialog in GTK 4.10 or greater). For more
  # information, see the GTK documentation and the XDG Portals specification.
  set -gx GTK_USE_PORTAL 1
  # The above environment variable was replaced by the below in GTK 4.7.1, but I
  # keep the old one set (for now) for any software using GTK 3 or an older
  # version of GTK 4. See: https://docs.gtk.org/gtk4/running.html#gdk_debug
  set -gx GDK_DEBUG portals

  # Force Firefox to use Wayland.
  set -gx MOZ_ENABLE_WAYLAND 1
end

# Improve font rendering in Java applications.
set -gx _JAVA_OPTIONS "$_JAVA_OPTIONS -Dawt.useSystemAAFontSettings=on -Dswing.aatext true"

if status is-login
  set -gxp PATH "$HOME/.local/bin" "$CARGO_HOME/bin" "$GOPATH/bin" $PATH
  set -gxp MANPATH "$RUSTUP_HOME/toolchains/stable-x86_64-unknown-linux-gnu/share/man"
end

# Everything beyond this point should only apply to interactive shells, so we
# exit early.
if not status is-interactive
  exit
end

# Get rid of the default greeting.
set fish_greeting

# Set fzf's colour scheme to Catppuccin Mocha.
set -x FZF_DEFAULT_OPTS \
 "--color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8 \
  --color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc \
  --color=marker:#f5e0dc,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8"

# Set the Linux console colour scheme to Catpuccin Mocha.
if test $TERM = "linux"
  printf %b "\e]P01E1E2E" # background color to "Base"
  printf %b "\e]P8585B70" # bright black to "Surface2"

  printf %b "\e]P7BAC2DE" # text color to "Text"
  printf %b "\e]PFA6ADC8" # bright white to "Subtext0"

  printf %b "\e]P1F38BA8" # red to "Red"
  printf %b "\e]P9F38BA8" # bright red to "Red"

  printf %b "\e]P2A6E3A1" # green to "Green"
  printf %b "\e]PAA6E3A1" # bright green to "Green"

  printf %b "\e]P3F9E2AF" # yellow to "Yellow"
  printf %b "\e]PBF9E2AF" # bright yellow to "Yellow"

  printf %b "\e]P489B4FA" # blue to "Blue"
  printf %b "\e]PC89B4FA" # bright blue to "Blue"

  printf %b "\e]P5F5C2E7" # magenta to "Pink"
  printf %b "\e]PDF5C2E7" # bright magenta to "Pink"

  printf %b "\e]P694E2D5" # cyan to "Teal"
  printf %b "\e]PE94E2D5" # bright cyan to "Teal"

  clear
end

abbr --add --global e $VISUAL
abbr --add --global s "sudo"
abbr --add --global y "yazi"
abbr --add --global cm "chezmoi"

# These Git aliases are modelled after the Magit key bindings.
abbr --add --global g "git"
abbr --add --global gC "git clone"
abbr --add --global gF "git pull"
abbr --add --global gI "git init"
abbr --add --global gM "git remote"
abbr --add --global gP "git push"
abbr --add --global gS "git switch"
abbr --add --global gV "git revert"
abbr --add --global gX "git reset"
abbr --add --global ga "git add"
abbr --add --global gb "git branch"
abbr --add --global gc "git commit"
abbr --add --global gd "git diff"
abbr --add --global gf "git fetch"
abbr --add --global gl "git log"
abbr --add --global gm "git merge"
abbr --add --global gr "git rebase"
abbr --add --global gs "git status"
abbr --add --global gt "git tag"
abbr --add --global gz "git stash"

if command -s zoxide &> /dev/null
  zoxide init fish | source
else
  echo "Note: zoxide is not installed"
end

if command -s eza &> /dev/null
  # TODO: Change this to use --hyperlink=auto once eza-community/eza#1059 is
  #       merged.
  set -l cmd "eza --color=auto --hyperlink --classify --group-directories-first" 
  alias ls $cmd
  alias ll "$cmd --long --header --group --git"
  alias la "ll --all"
  alias tree "$cmd --git-ignore --tree"
else
  echo "Note: eza is not installed"

  set -l cmd "ls --color=auto --hyperlink=auto --classify --group-directories-first"
  alias ls $cmd
  alias ll "$cmd --long --human-readable"
end

alias grep "grep --color=auto"
alias rg "rg --hyperlink-format=default"
alias ip "ip --color=auto"

alias lookbusy "cat /dev/urandom | hexdump -C | rg \"ca fe\""

# Make REPLs without line editing functionality less painful to use.
if command -s rlwrap &> "/dev/null"
  function wrap
    set -l cmd $argv[1]

    command -s $cmd &> "/dev/null"
    and alias $cmd "rlwrap --history-filename $XDG_DATA_HOME/rlwrap/$cmd-history $cmd"
  end

  set -l cmds ocaml coqtop clojure guile sbcl
  for cmd in $cmds
    wrap $cmd
  end

  functions --erase wrap
else
  echo "Note: rlwrap is not installed"
end

if command -s chez &> "/dev/null"
  alias chez "chez --eehistory $XDG_DATA_HOME/chez/history"
end

# Wrap yazi so that the current working directory is changed on exit.
function yazi
  set tmp (mktemp -t "yazi-cwd.XXXXXX")
  command yazi $argv --cwd-file="$tmp"
  if set cwd (command cat -- "$tmp"); and [ -n "$cwd" ]; and [ "$cwd" != "$PWD" ]
    builtin cd -- "$cwd"
  end
  rm -f -- "$tmp"
end
