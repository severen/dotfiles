#!/usr/bin/env bash

set -eu

# This script only exists to be used via `chezmoi update`.

BLUE='\033[0;34m'
GREY='\033[0;90m'
RESET='\033[0m'

exec_cmd() {
  echo -e "${BLUE}\$${RESET} $*"
  "$@"
}

exec_cmd jj git fetch
exec_cmd jj log

echo -e "${BLUE}=>${RESET} Proceed? ${GREY}[Y/n]${RESET}"
read -r answer
[[ "$answer" =~ ^[nN]$ ]] && exit

exec_cmd jj up

echo -e "${BLUE}\$${RESET} chezmoi apply"
