#!/usr/bin/env bash

function _arb_upgrade_current_epoch {
  local sec=${EPOCHSECONDS-}
  [[ $sec ]] || printf -v sec '%(%s)T' -1 2>/dev/null || sec=$(command date +%s)
  echo $((sec / 60 / 60 / 24))
}

function _arb_upgrade_update_timestamp {
  echo "LAST_EPOCH=$(_arb_upgrade_current_epoch)" >| ~/.osh-update
}

function _arb_upgrade_check {
  if [[ ! -f ~/.osh-update ]]; then
    # create ~/.osh-update
    _arb_upgrade_update_timestamp
    return 0
  fi

  local LAST_EPOCH
  . ~/.osh-update
  if [[ ! $LAST_EPOCH ]]; then
    _arb_upgrade_update_timestamp
    return 0
  fi

  # Default to the old behavior
  local epoch_expires=${UPDATE_ASH_DAYS:-6}
  local epoch_elapsed=$(($(_arb_upgrade_current_epoch) - LAST_EPOCH))
  if ((epoch_elapsed <= epoch_expires)); then
    return 0
  fi

  # update ~/.osh-update
  _arb_upgrade_update_timestamp
  if [[ $DISABLE_UPDATE_PROMPT == true ]] ||
       { read -p '[Oh My Bash] Would you like to check for updates? [Y/n]: ' line &&
           [[ $line == Y* || $line == y* || ! $line ]]; }
  then
    source "$ASH"/tools/upgrade.sh
  fi
}

# Cancel upgrade if the current user doesn't have write permissions for the
# arobash directory.
[[ -w "$ASH" ]] || return 0

# Cancel upgrade if git is unavailable on the system
type -P git &>/dev/null || return 0

if command mkdir "$ASH/log/update.lock" 2>/dev/null; then
  _arb_upgrade_check
  command rmdir "$ASH"/log/update.lock
fi
