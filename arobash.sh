#!/usr/bin/env bash

case $- in
  *i*) ;;
    *) return;;
esac

if [ -z "${BASH_VERSION-}" ]; then
	printf "arobash: Bash 3.2 or higher is required for Arobash.\n"
	printf "arobash: Please try runnning this script in Bash environment.\n"
	return 1
fi

_arb_bash_version=$((BASH_VERSINFO[0] * 10000 + BASH_VERSINFO[1] * 100 + BASH_VERSINFO[2]))
if ((_arb_bash_version < 30200)); then
  printf '%s\n' "arobash: ARB does not support this version of Bash ($BASH_VERSION)" >&2
  printf '%s\n' "arobash: Use ARB with Bash 3.2 or higher" >&2
  return 1
fi


ARB_VERSINFO=(1 0 0 0 main noarch)
ARB_VERSION="${ARB_VERSINFO[0]}.${ARB_VERSINFO[1]}.${ARB_VERSINFO[2]}(${ARB_VERSINFO[3]})-${ARB_VERSINFO[4]} (${ARB_VERSINFO[5]})"
_arb_version=$((ARB_VERSINFO[0] * 10000 + ARB_VERSINFO[1] * 100 + ARB_VERSINFO[2]))

# Check for updates on initial load...
if [[ $DISABLE_AUTO_UPDATE != true ]]; then
  source "$ASH"/tools/check_for_upgrade.sh
fi

# Initializes Arobash

# Set ASH_CUSTOM to the path where your custom config files
# and plugins exists, or else we will use the default custom/
: "${ASH_CUSTOM:=$ASH/custom}"

# Set ASH_CACHE_DIR to the path where cache files should be created
# or else we will use the default cache/
: "${ASH_CACHE_DIR:=$ASH/cache}"

_arb_module_loaded=
_arb_module_require() {
  local status=0
  local -a files=()
  while (($#)); do
    local type=lib name=$1; shift
    [[ $name == *:* ]] && type=${name%%:*} name=${name#*:}
    name=${name%.bash}
    name=${name%.sh}
    [[ ' '$_arb_module_loaded' ' == *" $type:$name "* ]] && continue
    _arb_module_loaded="$_arb_module_loaded $type:$name"

    local -a locations=()
    case $type in
    lib)        locations=({"$ASH_CUSTOM","$ASH"}/lib/"$name".{bash,sh}) ;;
    plugin)     locations=({"$ASH_CUSTOM","$ASH"}/plugins/"$name"/"$name".plugin.{bash,sh}) ;;
    alias)      locations=({"$ASH_CUSTOM","$ASH"}/aliases/"$name".aliases.{bash,sh}) ;;
    completion) locations=({"$ASH_CUSTOM","$ASH"}/completions/"$name".completion.{bash,sh}) ;;
    theme)      locations=({"$ASH_CUSTOM"{,/themes},"$ASH"/themes}/"$name"/"$name".theme.{bash,sh}) ;;
    *)
      echo "arobash (module_require): unknown module type '$type'." >&2
      status=2
      continue ;;
    esac

    local path
    for path in "${locations[@]}"; do
      if [[ -f $path ]]; then
        files+=("$path")
        continue 2
      fi
    done

    echo "arobash (module_require): module '$type:$name' not found." >&2
    status=127
  done

  if ((status==0)); then
    local path
    for path in "${files[@]}"; do
      source "$path" || status=$?
    done
  fi

  return "$status"
}

_arb_module_require_lib()        { _arb_module_require "${@/#/lib:}"; }
_arb_module_require_plugin()     { _arb_module_require "${@/#/plugin:}"; }
_arb_module_require_alias()      { _arb_module_require "${@/#/alias:}"; }
_arb_module_require_completion() { _arb_module_require "${@/#/completion:}"; }
_arb_module_require_theme()      { _arb_module_require "${@/#/theme:}"; }

# Load all of the config files in ~/.arobash/lib that end in .sh
# TIP: Add files you don't want in git to .gitignore
_arb_module_require_lib utils
_arb_util_glob_expand _arb_init_files '{"$ASH","$ASH_CUSTOM"}/lib/*.{bash,sh}'
_arb_init_files=("${_arb_init_files[@]##*/}")
_arb_init_files=("${_arb_init_files[@]%.bash}")
_arb_init_files=("${_arb_init_files[@]%.sh}")
_arb_module_require_lib "${_arb_init_files[@]}"
unset -v _arb_init_files

# Figure out the SHORT hostname
if [[ "$OSTYPE" = darwin* ]]; then
  # macOS's $HOST changes with dhcp, etc. Use ComputerName if possible.
  SHORT_HOST=$(scutil --get ComputerName 2>/dev/null) || SHORT_HOST=${HOST/.*/}
else
  SHORT_HOST=${HOST/.*/}
fi

# Load all of the plugins that were defined in ~/.bashrc
_arb_module_require_plugin "${plugins[@]}"

# Load all of the aliases that were defined in ~/.bashrc
_arb_module_require_alias "${aliases[@]}"

# Load all of the completions that were defined in ~/.bashrc
_arb_module_require_completion "${completions[@]}"

# Load all of your custom configurations from custom/
_arb_util_glob_expand _arb_init_files '"$ASH_CUSTOM"/*.{sh,bash}'
for _arb_init_file in "${_arb_init_files[@]}"; do
  [[ -f $_arb_init_file ]] &&
    source "$_arb_init_file"
done
unset -v _arb_init_files _arb_init_file

# Load the theme
if [[ $ASH_THEME == random ]]; then
  _arb_util_glob_expand _arb_init_files '"$ASH"/themes/*/*.theme.sh'
  if ((${#_arb_init_files[@]})); then
    _arb_init_file=${_arb_init_files[RANDOM%${#_arb_init_files[@]}]}
    source "$_arb_init_file"
    ARB_THEME_RANDOM_SELECTED=${_arb_init_file##*/}
    ARB_THEME_RANDOM_SELECTED=${ARB_THEME_RANDOM_SELECTED%.theme.bash}
    ARB_THEME_RANDOM_SELECTED=${ARB_THEME_RANDOM_SELECTED%.theme.sh}
    echo "[arobash] Random theme '$ARB_THEME_RANDOM_SELECTED' ($_arb_init_file) loaded..."
  fi
  unset -v _arb_init_files _arb_init_file
elif [[ $ASH_THEME ]]; then
  _arb_module_require_theme "$ASH_THEME"
fi

if [[ $PROMPT ]]; then
  export PS1="\["$PROMPT"\]"
fi

if ! _arb_util_command_exists '__git_ps1' ; then
  source "$ASH/tools/git-prompt.sh"
fi

# Adding Support for other OSes
[ -s /usr/bin/gloobus-preview ] && PREVIEW="gloobus-preview" ||
[ -s /Applications/Preview.app ] && PREVIEW="/Applications/Preview.app" || PREVIEW="less"
