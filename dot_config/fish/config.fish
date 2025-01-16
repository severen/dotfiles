if status is-interactive
  # Get rid of the default greeting.
  set fish_greeting

  set -x SHELL (command -s fish)

  if command -s starship &> "/dev/null"
    starship init fish | source
  end

  # Set fzf's colour scheme to Catppuccin Mocha.
  set -x FZF_DEFAULT_OPTS \
   "--color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8 \
    --color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc \
    --color=marker:#f5e0dc,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8"

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

  # This configuration is specific to my work laptop.
  if test $hostname = "yggdrasill"
    abbr --add --global consh "console ssh"
    alias mysth-console "docker exec -it -u mysth core_mysth_1 php console"
  end

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
  function yazi --wraps yazi
    set tmp (mktemp -t "yazi-cwd.XXXXXX")
    command yazi $argv --cwd-file="$tmp"
    if set cwd (command cat -- "$tmp"); and [ -n "$cwd" ]; and [ "$cwd" != "$PWD" ]
      builtin cd -- "$cwd"
    end
    rm -f -- "$tmp"
  end

  function system-color-scheme --description "Get the current system colour scheme"
    set -l color_scheme (
      busctl --user --json=short call \
        "org.freedesktop.portal.Desktop" \
        "/org/freedesktop/portal/desktop" \
        "org.freedesktop.portal.Settings" \
        ReadOne ss org.freedesktop.appearance color-scheme | jq .data[0].data
    )

    if test $color_scheme = 1
      echo "dark"
    else 
      echo "light"
    end
  end

  function bat --wraps bat
    if test (system-color-scheme) = "dark"
      set theme "Catppuccin Mocha"
    else
      set theme "Catppuccin Latte"
    end

    command bat --theme $theme $argv
  end

  function glow --wraps glow
    if test (system-color-scheme) = "dark"
      set theme "$XDG_CONFIG_HOME/glow/themes/catppuccin-mocha.json"
    else
      set theme "$XDG_CONFIG_HOME/glow/themes/catppuccin-latte.json"
    end

    command glow --style $theme $argv
  end
end
