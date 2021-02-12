#!/usr/bin/env bash

set -euo pipefail

PROGRAM="${0##*/}"
PREFIX="${SKEL_MANAGER_DIR:-$HOME/.skm}"

die() {
  echo "$@" >&2
  exit 1
}

#cmd_init() {
#  mkdir -vp "$PREFIX"
#}

#cmd_git {
#  case $1 in init...
#}

cmd_export() { # export to skel
  # TODO if not exists
  # TODO if not a link
  local arg_path="$1"
  local arg_path_abs; arg_path_abs="$(realpath --no-symlinks "$arg_path")"
  cp -v --no-dereference --preserve=all --parents "$arg_path_abs"  "$PREFIX/"
}

cmd_import() { # import from skel
  local arg_path="$1"
  local arg_path_abs; arg_path_abs="$(realpath --no-symlinks "$arg_path")"
  if [[ -d "$PREFIX/$arg_path" ]]; then
    # TODO first ensure that the destination files either match the source or don't exist
    cp -vr --no-dereference --preserve=all "$PREFIX/$arg_path/." "$arg_path_abs"
  else
    cp -v --no-dereference --preserve=all "$PREFIX/$arg_path" "$arg_path_abs"
  fi
}

cmd_pwd() {
  echo "$PREFIX"
}

#cmd_link() { # link from skel
#  # TODO if not exists
#  local arg_path="$1"
#  local arg_path_abs; arg_path_abs="$(realpath "$arg_path")"
#  local skm_path="$PREFIX$arg_path_abs"
#  git diff --no-index "$skm_path" "$arg_path"
#  #cp -v --parents "$(realpath "$1")" "$PREFIX/"
#}

cmd_diff() {
  src_target_expr="\$S $PREFIX/{}"
  [[ $1 == "export" ]] && src_target_expr="$PREFIX/{} \$S"
  shift
  local arg_path="${1:-/}"
  local arg_path_abs; arg_path_abs="$(realpath --no-symlinks "$arg_path")"
  local skm_path="$PREFIX$arg_path_abs"
  if [[ -L "$arg_path" && $(readlink -m "$arg_path") == "$skm_path" ]]; then
    die "'$arg_path_abs' is managed by skm. It is a symbolic link to '$skm_path'"
  fi
  if [[ -d "$skm_path" ]]; then
    # TODO if --stat run diff with --numstat
    # TODO do the diff in a single git diff call
    #find "$skm_path" -type f -not -path "$PREFIX/.git/*" -print0 | xargs -0 -I{} -- bash -c 'S={} && S=${S#'"$PREFIX"'} && if [[ ! -f $S ]]; then S=/dev/null; fi  && git --no-pager diff --color=always --no-index -- '"$src_target_expr"' && printf "%s matches\n" $S' | less -FRX
    # TODO test with path that contain all valid path characters (see https://dwheeler.com/essays/fixing-unix-linux-filenames.html)
    git -C "$PREFIX" ls-files -z "$skm_path" | xargs -0 -I{} -- bash -c 'S="/{}" && if [[ ! -f "/{}" ]]; then S=/dev/null; fi && git --no-pager diff --color=always --no-index -- '"$src_target_expr"' && printf "%s matches\n" $S' | less -FRX
  else
    git diff --no-index "$skm_path" "$arg_path"
  fi
}

cmd_list() {
  #if ! -v "$PREFIX"
  #if ! (git -C "$PREFIX" 2>/dev/null); then
  #  die "Error: '$PREFIX' is not a valid git directory. Run '$PROGRAM init' to initialize it."
  #  exit
  #fi
  #tree ~/.skm/
  local arg_path="${1-.}"
  local arg_path_abs; arg_path_abs="$(realpath "$arg_path")"
  local skm_path="$PREFIX/$arg_path"
  if [[ -d $skm_path ]]; then
    realpath "$skm_path"
    tree -aClI '.git' --noreport "$skm_path" | tail -n +2
  elif [[ -f $skm_path ]]; then
    ls -la "$skm_path"
  elif [[ $skm_path == "$PREFIX/" ]]; then
    die "Error: skel manager is not initialized. Try '$PROGRAM init'."
  else
    die "Error: '$arg_path_abs' is not managed by skm."
  fi
}

[[ $# -eq 0 ]] && cmd_list && exit

case $1 in
  diff) shift; die "Error: use either diff-export/dex/de or diff-import/dim/di" ;;
  diff-export|dex|de) shift; cmd_diff "export" "$@";;
  diff-import|dim|di) shift; cmd_diff "import" "$@";;
  export|ex|e) shift; cmd_export "$@" ;;
  import|im|i) shift; cmd_import "$@" ;;
  #init) shift; cmd_init "$@" ;; # TODO require a name; create $SKEL_MANAGER_DIR/skels/<name>
  #link) shift; cmd_link "$@" ;;
  list|ls) shift; cmd_list "$@" ;;
  pwd) shift; cmd_pwd ;;
  #TODO skel-list -- lists directories in $SKEL_MANAGER_DIR/skels
  #TODO skel-use -- links $SKEL_MANAGER_DIR/skels/current to skels/<name>
  *) cmd_list "$@" ;;
esac
