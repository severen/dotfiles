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

  abbr --add --global zzz "systemctl suspend"

  alias edit "eval $EDITOR"
  alias view "nvim -R"
  alias icat "kitty icat"
  alias lookbusy "cat /dev/urandom | hexdump -C | grep --color \"ca fe\""
  alias serve "python -m http.server"

  alias ls "ls --color=auto"
  alias lsx "ls --color=auto --long"
  alias grep "grep --color=auto"
  alias fgrep "fgrep --color=auto"
  alias egrep "egrep --color=auto"

  # Make the {OCaml,Coq,Clojure,Guile,SBCL} REPL less painful to use.
  if command -s rlwrap &> /dev/null
    command -s ocaml &> /dev/null; and alias ocaml "rlwrap ocaml"
    command -s sbcl &> /dev/null; and alias coqtop "rlwrap coqtop"
    command -s sbcl &> /dev/null; and alias clojure "rlwrap clojure"
    command -s sbcl &> /dev/null; and alias guile "rlwrap guile"
    command -s sbcl &> /dev/null; and alias sbcl "rlwrap sbcl"
  end

  if command -s exa &> /dev/null
    alias ls "exa --color=auto --classify --group-directories-first"
    alias lsx "exa --color=auto --classify --long --header --group --git --group-directories-first"
    alias tree "exa --color=auto --classify --git-ignore --tree"
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
