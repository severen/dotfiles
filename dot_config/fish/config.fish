if status is-interactive
  # Get rid of the default greeting.
  set fish_greeting

  set -x SHELL (command -s fish)

  # Set fzf's colour scheme to Catppuccin Mocha.
  set -x FZF_DEFAULT_OPTS \
   "--color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8 \
    --color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc \
    --color=marker:#f5e0dc,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8"

  abbr --add --global e $VISUAL
  abbr --add --global cm "chezmoi"
  abbr --add --global s "sudo"

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
    set -l cmd "eza --color=auto --classify --group-directories-first" 
    alias ls $cmd
    alias ll "$cmd --long --header --group --git"
    alias la "ll --all"
    alias tree "$cmd --git-ignore --tree"
  else
    echo "Note: eza is not installed"

    set -l cmd "ls --color=auto --classify --group-directories-first"
    alias ls $cmd
    alias ll "$cmd --long --human-readable"
  end

  alias grep "grep --color=auto"

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

  # Prevent nested ranger instances.
  function ranger
    if not set -q RANGER_LEVEL
      command ranger $argv
    else
      exit
    end
  end
end
