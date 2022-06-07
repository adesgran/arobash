#!/usr/bin/env bash

function _arb_upgrade {
  # Use colors, but only if connected to a terminal, and that terminal
  # supports them.
  if type -P tput &>/dev/null; then
    local ncolors=$(tput colors)
  fi

  if [[ -t 1 && $ncolors && $ncolors -ge 8 ]]; then
    local RED=$(tput setaf 1)
    local GREEN=$(tput setaf 2)
    local YELLOW=$(tput setaf 3)
    local BLUE=$(tput setaf 4)
    local BOLD=$(tput bold)
    local NORMAL=$(tput sgr0)
  else
    local RED=""
    local GREEN=""
    local YELLOW=""
    local BLUE=""
    local BOLD=""
    local NORMAL=""
  fi

  printf "${BLUE}%s${NORMAL}\n" "Updating Arobash"

  # Note: The git option "-C PATH" is only supported from git-1.8.5
  # (https://github.com/git/git/commit/44e1e4d6 2013-09).  On the other hand,
  # the synonym "--git-dir=PATH/.git --work-tree=PATH" is supported from
  # git-1.5.3 (https://github.com/git/git/commit/892c41b9 2007-06).
  if ! command git --git-dir="$ASH/.git" --work-tree="$ASH" pull --rebase --stat origin main; then
    # In case it enters the rebasing mode
    printf '%s\n' "arobash: running 'git rebase --abort'..."
    command git --git-dir="$ASH/.git" --work-tree="$ASH" rebase --abort
    printf "${RED}%s${NORMAL}\n" \
           'There was an error updating.' \
           "If you have uncommited changes in '$BOLD$ASH$NORMAL$RED', please commit, stash or discard them and retry updating." \
           "If you have your own local commits in '$BOLD$ASH$NORMAL$RED' that conflict with the upstream changes, please resolve conflicts and merge the upstream manually."
    return 1
  fi

  printf '%s' "$GREEN" 
	printf	"  ___            _                 _     " 
	printf	" / _ \          | |      ____     | |    " 
	printf	"/ /_\ \_ __ ___ | |__   / __ \ ___| |__  "
	printf	"|  _  | '__/ _ \| '_ \ / / _\` / __| '_ \ "
	printf	"| | | | | | (_) | |_) | | (_| \__ \ | | |"
	printf	"\_| |_/_|  \___/|_.__/ \ \__,_|___/_| |_|"
	printf	"                        \____/" 
  printf "${BLUE}%s\n" "Hooray! Arobash has been updated and/or is at the current version."
  printf "${BLUE}${BOLD}%s${NORMAL}\n" "To keep up on the latest news and updates, follow us on GitHub: https://github.com/adesgran/arobash"
  if [[ $- == *i* ]]; then
    declare -f _arb_util_unload &>/dev/null && _arb_util_unload
    source ~/.bashrc
  fi
}
_arb_upgrade
