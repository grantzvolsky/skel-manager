#!/usr/bin/env bash

set -euo pipefail

PROGRAM="${0##*/}"
REPO_PATH="$(realpath "${SKEL_MANAGER_DIR:-$HOME/.skm}")"
SKEL_PATH="$(realpath "$REPO_PATH"/skels/current)"
SKEL_PATH_REL="${SKEL_PATH#$REPO_PATH}"

die() {
  echo "$@" >&2
  exit 1
}

#cmd_init() {
#  mkdir -vp "$REPO_PATH/skels/current"
#  touch "$REPO_PATH"/README
#}

#cmd_git {
#  case $1 in init...
#}

cmd_export() { # export to skel
  # TODO if not exists
  # TODO if not a link
  local arg_path="$1"
  local arg_path_abs; arg_path_abs="$(realpath --no-symlinks "$arg_path")"
  cp -v --no-dereference --preserve=all --parents "$arg_path_abs"  "$SKEL_PATH/"
}

cmd_import() { # import from skel
  local arg_path="$1"
  local arg_path_abs; arg_path_abs="$(realpath --no-symlinks "$arg_path")"
  if [[ -d "$SKEL_PATH/$arg_path" ]]; then
    # TODO first ensure that the destination files either match the source or don't exist
    cp -vr --no-dereference --preserve=all "$SKEL_PATH/$arg_path/." "$arg_path_abs"
  else
    cp -v --no-dereference --preserve=all "$SKEL_PATH/$arg_path" "$arg_path_abs"
  fi
}

cmd_pwd() {
  echo "$SKEL_PATH"
}

#cmd_link() { # link from skel
#  # TODO if not exists
#  local arg_path="$1"
#  local arg_path_abs; arg_path_abs="$(realpath "$arg_path")"
#  local skm_path="$SKEL_PATH$arg_path_abs"
#  git diff --no-index "$skm_path" "$arg_path"
#  #cp -v --parents "$(realpath "$1")" "$SKEL_PATH/"
#}

cmd_diff() {
  src_target_expr="\$S $SKEL_PATH{}"
  [[ $1 == "export" ]] && src_target_expr="$SKEL_PATH{} \$S"
  shift
  local arg_path="${1:-/}"
  local arg_path_abs; arg_path_abs="$(realpath --no-symlinks "$arg_path")"
  local skm_path="$SKEL_PATH$arg_path_abs"
  if [[ -L "$arg_path" && $(readlink -m "$arg_path") == "$skm_path" ]]; then
    die "'$arg_path_abs' is managed by skm. It is a symbolic link to '$skm_path'"
  elif [[ -d "$skm_path" ]]; then
    # TODO if --stat run diff with --numstat
    # TODO do the diff in a single git diff call
    #find "$skm_path" -type f -not -path "$PREFIX/.git/*" -print0 | xargs -0 -I{} -- bash -c 'S={} && S=${S#'"$PREFIX"'} && if [[ ! -f $S ]]; then S=/dev/null; fi  && git --no-pager diff --color=always --no-index -- '"$src_target_expr"' && printf "%s matches\n" $S' | less -FRX
    # TODO test with path that contain all valid path characters (see https://dwheeler.com/essays/fixing-unix-linux-filenames.html)
    #echo $SKEL_MANAGER_DIR
    #echo $SKEL_PATH
    #echo $skm_path
    #git -C "$REPO_PATH" ls-files "$skm_path" | cut -c"${#SKEL_PATH_REL}"-
    git -C "$REPO_PATH" ls-files -z "$skm_path" | cut -zc"${#SKEL_PATH_REL}"- | xargs -0 -I{} -- bash -c 'S="{}" && if [[ ! -f "{}" ]]; then S=/dev/null; fi && git --no-pager diff --color=always --no-index -- '"$src_target_expr"' && printf "%s matches\n" $S' | less -FRX
    #git -C "$SKEL_MANAGER_DIR" ls-files -z "$skm_path" | cut -c"${#SKEL_PATH_REL}"- | xargs -0 -I{} -- bash -c 'S="{}" && if [[ ! -f "{}" ]]; then S=/dev/null; fi && git --no-pager diff --color=always --no-index -- '"$src_target_expr"' && printf "%s matches\n" $S' | less -FRX
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
  local skm_path="$SKEL_PATH/$arg_path"
  if [[ -d $skm_path ]]; then
    realpath "$skm_path"
    tree -aClI '.git' --noreport "$skm_path" | tail -n +2
  elif [[ -f $skm_path ]]; then
    ls -la "$skm_path"
  elif [[ $skm_path == "$SKEL_PATH/" ]]; then
    die "Error: skel manager is not initialized. Try '$PROGRAM init'."
  else
    die "Error: '$arg_path_abs' is not managed by skm."
  fi
}

cmd_watch() { # TODO --no-snapshot flag to avoid copying large directories
  tmp_dir=$(mktemp -d)
  echo "INFO: Creating a snapshot of '$1'."
  cp -a "$1" "$tmp_dir"
  trap "git diff --no-index $tmp_dir $1" EXIT # TODO work out how to specify source and destination roots in order to consider files with the same in-root path identical; git diff currently marks all files as renamed because their paths are different
  inotifywait -m -r "$1"
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
  watch) shift; cmd_watch "$@";;
  #TODO skel-list -- lists directories in $SKEL_MANAGER_DIR/skels
  #TODO skel-use -- links $SKEL_MANAGER_DIR/skels/current to skels/<name>
  *) cmd_list "$@" ;;
esac
