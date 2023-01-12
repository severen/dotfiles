if status is-interactive
  # Get rid of the default greeting.
  set fish_greeting

  set -x SHELL (command -s fish)

  # Set the FZF colour scheme to Catppuccin Mocha.
  set -x FZF_DEFAULT_OPTS "\
    --color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8 \
    --color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc \
    --color=marker:#f5e0dc,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8"

  # Some safe(r) abbreviations for file commands.
  abbr --add --global rm "rm -vI"
  abbr --add --global rmi "rm -vi"
  abbr --add --global mv "mv -vn"
  abbr --add --global mvi "mv -vi"

  abbr --add --global e "$VISUAL"

  # Git (modelled after the Magit keybindings)
  abbr --add --global g "git"
  abbr --add --global ga "git add"
  abbr --add --global gC "git clone"
  abbr --add --global gF "git pull"
  abbr --add --global gI "git init"
  abbr --add --global gM "git remote"
  abbr --add --global gO "git subtree"
  abbr --add --global gP "git push"
  abbr --add --global gS "git switch"
  abbr --add --global gV "git revert"
  abbr --add --global gX "git reset"
  abbr --add --global gb "git branch"
  abbr --add --global gc "git commit"
  abbr --add --global gd "git diff"
  abbr --add --global gf "git fetch"
  abbr --add --global gl "git log"
  abbr --add --global gm "git merge"
  abbr --add --global go "git submodule"
  abbr --add --global gr "git rebase"
  abbr --add --global gs "git status"
  abbr --add --global gt "git tag"
  abbr --add --global gz "git stash"

  # Chezmoi
  abbr --add --global cm "chezmoi"
  abbr --add --global cma "chezmoi apply"
  abbr --add --global cmc "chezmoi cd"
  abbr --add --global cme "chezmoi edit --apply"

  # systemd
  abbr --add --global sctl "systemctl"
  abbr --add --global zzz "systemctl suspend"

  if command -s exa &> /dev/null
    set cmd "exa --color=auto --classify --group-directories-first" 
    alias ls $cmd
    alias lx "$cmd --long --header --group --git"
    alias la "$cmd --all --long --header --group --git"
    alias tree "$cmd --git-ignore --tree"
  else
    echo "Note: exa is not installed"

    set cmd "ls --color=auto --classify --group-directories-first"
    alias ls $cmd
    alias lx "$cmd -l --author --human-readable"
  end

  alias grep "grep --color=auto"
  alias fgrep "fgrep --color=auto"
  alias egrep "egrep --color=auto"

  alias serve "python -m http.server"
  alias lookbusy "cat /dev/urandom | hexdump -C | rg \"ca fe\""

  # Make REPLs without line editing functionality less painful to use.
  if command -s rlwrap &> "/dev/null"
    function wrap
      set cmd $argv[1]

      command -s $cmd &> "/dev/null"
      and alias $cmd "rlwrap --history-filename $XDG_DATA_HOME/rlwrap/$cmd-history $cmd"
    end

    set cmds ocaml coqtop clojure guile sbcl
    for cmd in $cmds
      wrap $cmd
    end

    functions --erase wrap
  else
    echo "Note: rlwrap is not installed"
  end

  # Prevent nested ranger instances.
  function ranger
    if not set -q RANGER_LEVEL
      command ranger $argv
    else
      exit
    end
  end
end
