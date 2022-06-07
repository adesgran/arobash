#!/usr/bin/env bash

# Note: this file is intentionally written in POSIX sh so that arobash can
# be uninstalled without bash.

_arb_uninstall_contains_arb() {
  command grep -qE '(source|\.)[[:space:]]+.*[/[:space:]]arobash\.sh' "$1" 2>/dev/null
}

# Find the latest bashrc that do not source arobash.sh
_arb_uninstall_find_bashrc_original() {
  _arb_uninstall_bashrc_original=
  printf '%s\n' "Looking for original bash config..."
  IFS='
'
  for _arb_uninstall_file in $(printf '%s\n' ~/.bashrc.arb-backup-?????????????? | sort -r) ~/.bashrc.pre-arobash; do
    [ -f "$_arb_uninstall_file" ] || [ -h "$_arb_uninstall_file" ] || continue
    _arb_uninstall_contains_arb "$_arb_uninstall_file" && continue
    _arb_uninstall_bashrc_original=$_arb_uninstall_file
    break
  done
  unset _arb_uninstall_file
  IFS=' 	
'
  if [ -n "$_arb_uninstall_bashrc_original" ]; then
    printf '%s\n' "-> Found at '$_arb_uninstall_bashrc_original'."
  else
    printf '%s\n' "-> Not found."
  fi
}

read -r -p "Are you sure you want to remove Arobash? [y/N] " _arb_uninstall_confirmation
if [ "$_arb_uninstall_confirmation" != y ] && [ "$_arb_uninstall_confirmation" != Y ]; then
  printf '%s\n' "Uninstall cancelled"
  unset _arb_uninstall_confirmation
  return 0 2>/dev/null || exit 0
fi
unset _arb_uninstall_confirmation

if [ -d ~/.arobash ]; then
  printf '%s\n' "Removing ~/.arobash"
  command rm -rf ~/.arobash
fi

_arb_uninstall_bashrc_original=
_arb_uninstall_find_bashrc_original

if ! _arb_uninstall_contains_arb ~/.bashrc; then
  printf '%s\n' "uninstall: Arobash does not seem to be installed in .bashrc." >&2
  if [ -n "$_arb_uninstall_bashrc_original" ]; then
    printf '%s\n' "uninstall: The original config was found at '$_arb_uninstall_bashrc_original'." >&2
  fi
  printf '%s\n' "uninstall: Canceled." >&2
  unset _arb_uninstall_bashrc_original
  return 1 2>/dev/null || exit 1
fi

_arb_uninstall_bashrc_uninstalled=
if [ -e ~/.bashrc ] || [ -h ~/.bashrc ]; then
  _arb_uninstall_bashrc_uninstalled=".bashrc.arb-uninstalled-$(date +%Y%m%d%H%M%S)";
  printf '%s\n' "Found ~/.bashrc -- Renaming to ~/${_arb_uninstall_bashrc_uninstalled}";
  command mv ~/.bashrc ~/"${_arb_uninstall_bashrc_uninstalled}";
fi

if [ -n "$_arb_uninstall_bashrc_original" ]; then
  printf '%s\n' "Found $_arb_uninstall_bashrc_original -- Restoring to ~/.bashrc";
  command mv "$_arb_uninstall_bashrc_original" ~/.bashrc;
  printf '%s\n' "Your original bash config was restored. Please restart your session."
else
  command sed '/arobash\.sh/s/^/: #/' ~/"${_arb_uninstall_bashrc_uninstalled:-.bashrc}" >| ~/.bashrc.arb-temp && \
    command mv ~/.bashrc.arb-temp ~/.bashrc
fi

unset _arb_uninstall_bashrc_original
unset _arb_uninstall_bashrc_uninstalled

echo "Thanks for trying out Arobash. It has been uninstalled."
case $- in
*i*)
  if [ -n "${BASH_VERSION-}" ]; then
    declare -f _arb_util_unload >/dev/null 2>&1 && _arb_util_unload
    source ~/.bashrc
  fi ;;
esac
