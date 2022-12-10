#!/usr/bin/env bash

set -exo pipefail

BINARY_NAME="${0##*/}"

die() {
  echo "$@" >&2
  exit 1
}

#if [[ ! -d "$GOM_GIT_DIR" ]]; then
#  die "[ERROR]: GOM_GIT_DIR=${GOM_GIT_DIR} is not a directory"
#fi

cmd_copy_overlay_skel() {
  # TODO
  # TODO only run this cmd if the path is not a lowerdir in a mounted overlay
  return
}

cmd_diff_export() {
  #if cat /proc/mounts | grep 'upperdir='$upperdir | awk '$1=="overlay" {print $2}'; then
  #  die "[ERROR]: $upperdir is mounted or"
  #fi
  return
}

cmd_list() {
  if [ "$#" -eq 0 ]; then
    cat /proc/mounts | grep 'upperdir='${GOM_WORK_TREE} | awk '$1=="overlay" {print $2}'
    #mount -t overlay | grep 'upperdir='${GOM_WORK_TREE}
    exit
  fi

  if [ "$#" -eq 1 ]; then
    git init /tmp/wx-empty-git-dir || true
    pushd /
      git --git-dir=/tmp/wx-empty-git-dir/.git ls-files "$1" --other
    popd
    #git --git-dir=/tmp/wx-empty-git-dir/.git ls-files /var --other -X /tmp/.gitignore
    #git --git-dir=/tmp/test/.git ls-files /var --other -X /tmp/.gitignore
    exit
  fi

  if [ "$#" -eq 2 ]; then
    git init /tmp/wx-empty-git-dir || true
    #git --git-dir=/tmp/wx-empty-git-dir/.git ls-files /var --other -X /tmp/.gitignore
    pushd /
      git --git-dir=/tmp/wx-empty-git-dir/.git ls-files "$1" --other -X "$2"
    popd
    #git --git-dir=/tmp/test/.git ls-files /var --other -X /tmp/.gitignore
    exit
  fi

  die "Usage: $BINARY_NAME ls [path [--ignore-file=<path>]]"
}

cmd_usage() {
  set +x
  cat <<- EOF
	NAME
		${BINARY_NAME} - Overlay-based Filetree Tracker

	SYNOPSIS
		${BINARY_NAME} <command> [<args>]

	COMMANDS
	  init
	  ignore
	  copy-skel-overlay
	  copy-overlay-skel
	  diff-skel-overlay
	  diff-overlay-skel
	  list
	  mount
	  pwd
	  repo-clean
	  umount
	  watch
EOF
  exit
}

cmd_init() {
  if [ "$#" -ne 2 ]; then
    echo "Usage: ${BINARY_NAME} init <rootfs-path> <git-dir>"
    echo "<git-dir> is the .git dir with metadata for the repository at <rootfs-path>. It must be outside <rootfs-path> so that rootfs can contain unrelated git repositories."
    exit 1
  fi
  local rootfs_path="$1"
  local git_dir_path="$2"

  if [[ -e "$rootfs_path" ]]; then
    die "[ERROR]: ${rootfs_path} already exists"
  fi

  if [[ -e "$git_dir_path" ]]; then
    die "[ERROR]: ${git_dir_path} already exists"
  fi

  echo '[INFO] Use the commands below to initialize the skel repository'
  echo 'git init '"$rootfs_path"
  echo 'mv '"$rootfs_path"'/.git '"$git_dir_path"
  echo '[INFO] Add the following variables to your profile'
  echo "GOM_WORK_TREE=${rootfs_path}"
  echo "GOM_GIT_DIR=${git_dir_path}"
  echo '[INFO] Finally, use this alias to manipulate the skel repository'
  echo "alias s='git --git-dir=\$GOM_GIT_DIR --work-tree=\$GOM_WORK_TREE'"
}

cmd_diff_skel_overlay() {
  # TODO args

  git --git-dir="$GOM_GIT_DIR" --work-tree="$GOM_WORK_TREE" update-index --refresh
  if ! git --git-dir="$GOM_GIT_DIR" --work-tree="$GOM_WORK_TREE" diff-index HEAD --quiet --; then
    echo 'Error: overlay working tree is dirty; all changes need to be committed in order to run the diff' >&2
    exit 1
  fi

  if [[ "$1" == "--stat"  ]]; then
    git --git-dir="$GOM_GIT_DIR" --work-tree="/" diff -R --stat -- "${2:-/}"
  else
    git --git-dir="$GOM_GIT_DIR" --work-tree="/" diff -R -- "${1:-/}"
  fi

}

cmd_diff_overlay_skel() {
  # TODO args


  git --git-dir="$GOM_GIT_DIR" --work-tree="$GOM_WORK_TREE" update-index --refresh
  if ! git --git-dir="$GOM_GIT_DIR" --work-tree="$GOM_WORK_TREE" diff-index HEAD --quiet --; then
    echo 'Error: overlay working tree is dirty; all changes need to be committed in order to run the diff' >&2
    exit 1
  fi

  if [[ "$1" == "--stat"  ]]; then
    git --git-dir="$GOM_GIT_DIR" --work-tree="/" diff --stat -- "${2:-/}"
  else
    git --git-dir="$GOM_GIT_DIR" --work-tree="/" diff -- "${1:-/}"
  fi

}

cmd_ignore() {
  if [ "$#" -eq 0 ]; then
    git --git-dir="$GOM_GIT_DIR" --work-tree="$GOM_WORK_TREE" status --porcelain --ignored | grep '^!!'
  else
    echo "$@" >> $GOM_WORK_TREE/.gitignore
  fi
}

ensure_repo_clean() {
  pushd "$GOM_WORK_TREE"
    CFS=$(find . -type b,c,p,f,l,s | wc -l)
    CGIT=$(git --git-dir="$GOM_GIT_DIR" --work-tree="$GOM_WORK_TREE" ls-files | wc -l)
  popd
  if [ ! $CFS -eq $CGIT ]; then
    die "$GOM_GIT_DIR is not clean"
  fi
}

cmd_merge_skel_overlay() {
  # TODO require overlay to be unmounted...
  # TODO expand ~
  git merge-file -p "/$1" /dev/null "$GOM_WORK_TREE/$1"
}

cmd_merge_overlay_skel() {
  # TODO require overlay to be unmounted...
  # TODO expand ~
  git merge-file -p "/$1" /dev/null "$GOM_WORK_TREE/$1"
}

cmd_copy_overlay_skel() {
  if [[ "$1" == "--all" ]]; then
    git --git-dir="$GOM_GIT_DIR" --work-tree="$GOM_WORK_TREE" update-index --refresh
    if ! git --git-dir="$GOM_GIT_DIR" --work-tree="$GOM_WORK_TREE" diff-index HEAD --quiet --; then
      echo 'Error: overlay working tree is dirty; all changes need to be committed in order to run a diff and apply changes to skel' >&2
      exit 1
    fi

    # TODO dry run: the following patch will be applied to skel
    # TODO allow patching parts of the filetree
    #git --git-dir="$GOM_GIT_DIR" --work-tree="/" update-index --assume-unchanged /.gitignore
    #git --git-dir="$GOM_GIT_DIR" --work-tree="/" update-index --no-assume-unchanged /.gitignore
    git --git-dir="$GOM_GIT_DIR" --work-tree="/" update-index --skip-worktree /.gitignore
    git --git-dir="$GOM_GIT_DIR" --work-tree="/" diff -R | git --git-dir="$GOM_GIT_DIR" --work-tree="/" apply --stat
    git --git-dir="$GOM_GIT_DIR" --work-tree="/" update-index --no-skip-worktree /.gitignore

    return
  fi
  cp "$GOM_WORK_TREE/$1" "/$1"
}

cmd_copy_skel_overlay() {
  cp "/$1" "$GOM_WORK_TREE/$1"
}

cmd_mount() {
  ensure_repo_clean
  local upperdir=${GOM_WORK_TREE}/$1
  if [ "$#" -ne 1 ]; then
    echo "Usage: ${BINARY_NAME} mount <path>"
    echo "Mounts GOM_WORK_TREE<path> at <path>."
    exit 1
  fi
  if [[ ! "$1" =~ ^/.*$ ]]; then
    die '$1 must be an absolute path'
  fi
  if cat /proc/mounts | grep 'upperdir='$upperdir | awk '$1=="overlay" {print $2}'; then
    die "[ERROR]: $upperdir is already mounted or"
  fi
  mkdir -p /tmp/ftr-overlay-workdir
  mkdir -p $GOM_WORK_TREE$1
  sudo mount -t overlay overlay -o workdir=/tmp/ftr-overlay-workdir,lowerdir=$1,upperdir=$upperdir $1
}

cmd_umount() {
  local upperdir=${GOM_WORK_TREE}$1
  if cat /proc/mounts | grep 'upperdir='$upperdir'/'; then
    echo "[ERROR]: $upperdir is a parent to other mounts; please umount these first"
    cmd_list
    exit
  fi
  if sudo umount -t overlay $1; then
    exit
  else
    { echo "[ERROR] Failed to umount ${1}; fuser may indicate why:"; } > 2 > /dev/null
    fuser -vm $1
  fi
}

cmd_pwd() {
  echo "$GOM_WORK_TREE"
}

cmd_overlay_clean() {
  pushd $GOM_WORK_TREE
    find . -type c | xargs -I{} rm '{}'
    git --git-dir="$GOM_GIT_DIR" --work-tree="$GOM_WORK_TREE" ls-files --others | xargs -I{} rm '{}'
    find . -type d -empty | xargs -I{} rmdir '{}'
  popd
}

# TODO document the fact that files can be "checked into" the work tree using the touch command
# TODO test what happens when a git checkout is run on an active overlay and implement the `s` command in a way that doesn't allow any modifications of the work tree by git itself

# ft: overlay-based filesystem tracker
# from the perspective of sod, your rootfs becomes a skel directory
# sot then tracks the changes to interesting parts of your filesystem
# it does so by holding the changes in an [overlay](...), and tracking
# the overlay as a git repository
#
# skel: a read-only filetree on top of which a user environment is built
#
# note that this is different from how skel directories have been used traditionally
# in other contexts, the skel is located in a separate path, wuch as /etc/skel
# sod fuses the skel and its mutations using overlayfs. the paths in the skel
# are the same as the paths in the live filesystem, which is now an overlayfs.
# the skel is activated not by copying contents from /etc/skel. instead, skel
# becomes the default state of your filesystem, and you apply your changes to
# the skel by mounting the overlay.
# sod allows you to move files back and forth between the skel and the overlay,
# and to track changes using git
#
# the use of git is optional; it is, however, strongly recommended to frequently backup your overlay, and sod allows you to do this easily when used with git
# 
#
# by overlay, we mean the upper directory of an overlayfs
# by skel, we mean the lower directory of an overlayfs
#
# there are two crucial paths that sot needs to know at all times:
# 1. the path to your skel, which could be `/` or your home directory
# 2. the path to the overlay
#
# TODO

# # simple mode:
# diff / overlay
# - when overlay is mounted, the diff is always zero
# diff overlay /
# - when overlay is mounted, the diff is always zero
# 
# # git mode
# when using git mode, overlay ceases to be just a plain directory, and becomes a git repository
# the repository can be viewed at different states, and you might want to view a diff of the different states
# to diff different states of the overlay, use the git command with the parameters --work-tree=... and --work-dir; ftr encourages you to make a git alias
# to save you from typing them out every time
# 
# git mode adds a constraint on running the ftr diff command: in order for it to give you meaningful results, the repository must not be dirty; that means
# no uncommitted changes or staged chagnes
# 
# diff / overlay-work-tree - only allowed if there are no staged
# diff / overlay-index - not allowed; use git diff --work-tree=... --work-dir=... <commit> instead
# diff / overlay-staging - not allowed
# diff overlay-work-tree /
# diff overlay-work-tree overlay-index
# diff overlay-work-tree overlay-staging
# diff overlay-index /
# diff overlay-index overlay-work-tree
# diff overlay-index overlay-staging
# diff overlay-staging overlay-index
# diff overlay-staging overlay-work-tree
# diff overlay-staging /

cmd_watch() { # TODO --no-snapshot flag to avoid copying large directories
  tmp_dir=$(mktemp -d)
  echo "INFO: Creating a snapshot of '$1'."
  cp -a "$1" "$tmp_dir"
  trap "git diff --no-index $tmp_dir $1" EXIT # TODO work out how to specify source and destination roots in order to consider files with the same in-root path identical; git diff currently marks all files as renamed because their paths are different
  inotifywait -m -r "$1"
}

[[ $# -eq 0 ]] && cmd_usage && exit

case $1 in
  init) shift; cmd_init "$@" ;;
  ignore) shift; cmd_ignore "$@" ;;
  diff-overlay-skel|dos|osd) shift; cmd_diff_overlay_skel "$@" ;; # this tells you what changes will take place when you umount the overlay or copy files from skel to overlay
  diff-skel-overlay|dso|sod) shift; cmd_diff_skel_overlay "$@" ;; # this tells you what changes will take place when you mount the overlay or copy files form overlay to skel
  copy-overlay-skel|cos|osc) shift; cmd_copy_overlay_skel "$@" ;;
  copy-skel-overlay|cso|soc) shift; cmd_copy_skel_overlay "$@" ;;
# skel-molt|skel-backup - copy files tracked by git into a new directory containing the skel counterparts of the overlay
  merge-overlay-skel|mos|osm) shift; cmd_merge_overlay_skel "$@" ;; # a helper to merge files present in both skel and overlay
  merge-skel-overlay|mso|som) shift; cmd_merge_skel_overlay "$@" ;; # a helper to merge files present in both skel and overlay
  list|ls) shift; cmd_list "$@" ;;
  mount) shift; cmd_mount "$@" ;;
  pwd) shift; cmd_pwd ;;
  overlay-clean|oc) shift; cmd_overlay_clean ;;
  umount) shift; cmd_umount "$@" ;;
  watch) shift; cmd_watch "$@";;
  *) cmd_usage ;;
esac

# PROGRAM="${0##*/}"
# REPO_PATH="$(realpath "${SKEL_MANAGER_DIR:-$HOME/.skm}")"
# SKEL_PATH="$(realpath "$REPO_PATH"/skels/current)"
# SKEL_PATH_REL="${SKEL_PATH#$REPO_PATH}"
# 
# cmd_git() { # TODO completion
#   git -C "$SKEL_PATH" "$@"
# }
# 
# cmd_export() { # export to skel
#   # TODO if not exists
#   # TODO if not a link
#   local arg_path="$1"
#   if [[ ! -f $arg_path ]]; then
#     rm "$SKEL_PATH$arg_path"
#     return
#   fi
#   local arg_path_abs; arg_path_abs="$(realpath --no-symlinks "$arg_path")"
#   cp -v --no-dereference --preserve=all --parents "$arg_path_abs"  "$SKEL_PATH/"
# }
# 
# cmd_import() { # import from skel
#   local arg_path="$1"
#   local arg_path_abs; arg_path_abs="$(realpath --no-symlinks "$arg_path")"
#   if [[ -d "$SKEL_PATH/$arg_path" ]]; then
#     # TODO first ensure that the destination files either match the source or don't exist
#     cp -vr --no-dereference --preserve=all "$SKEL_PATH/$arg_path/." "$arg_path_abs"
#   else
#     cp -v --no-dereference --preserve=all "$SKEL_PATH/$arg_path" "$arg_path_abs"
#   fi
# }
# 
# #cmd_link() { # link from skel
# #  # TODO if not exists
# #  local arg_path="$1"
# #  local arg_path_abs; arg_path_abs="$(realpath "$arg_path")"
# #  local skm_path="$SKEL_PATH$arg_path_abs"
# #  git diff --no-index "$skm_path" "$arg_path"
# #  #cp -v --parents "$(realpath "$1")" "$SKEL_PATH/"
# #}
# 
# cmd_diff() {
#   src_target_expr="\$S $SKEL_PATH{}"
#   [[ $1 == "export" ]] && src_target_expr="$SKEL_PATH{} \$S"
#   shift
#   local arg_path="${1:-/}"
#   local arg_path_abs; arg_path_abs="$(realpath --no-symlinks "$arg_path")"
#   local skm_path="$SKEL_PATH$arg_path_abs"
#   if [[ -L "$arg_path" && $(readlink -m "$arg_path") == "$skm_path" ]]; then
#     die "'$arg_path_abs' is managed by skm. It is a symbolic link to '$skm_path'"
#   elif [[ -d "$skm_path" ]]; then
#     # TODO if --stat run diff with --numstat
#     # TODO do the diff in a single git diff call
#     #find "$skm_path" -type f -not -path "$PREFIX/.git/*" -print0 | xargs -0 -I{} -- bash -c 'S={} && S=${S#'"$PREFIX"'} && if [[ ! -f $S ]]; then S=/dev/null; fi  && git --no-pager diff --color=always --no-index -- '"$src_target_expr"' && printf "%s matches\n" $S' | less -FRX
#     # TODO test with path that contain all valid path characters (see https://dwheeler.com/essays/fixing-unix-linux-filenames.html)
#     #echo $SKEL_MANAGER_DIR
#     #echo $SKEL_PATH
#     #echo $skm_path
#     #git -C "$REPO_PATH" ls-files "$skm_path" | cut -c"${#SKEL_PATH_REL}"-
#     git -C "$REPO_PATH" ls-files -z "$skm_path" | cut -zc"${#SKEL_PATH_REL}"- | xargs -0 -I{} -- bash -c 'S="{}" && if [[ ! -f "{}" ]]; then S=/dev/null; fi && git --no-pager diff --color=always --no-index -- '"$src_target_expr" | less -FRX
#     #git -C "$SKEL_MANAGER_DIR" ls-files -z "$skm_path" | cut -c"${#SKEL_PATH_REL}"- | xargs -0 -I{} -- bash -c 'S="{}" && if [[ ! -f "{}" ]]; then S=/dev/null; fi && git --no-pager diff --color=always --no-index -- '"$src_target_expr"' && printf "%s matches\n" $S' | less -FRX
#   else
#     git diff --no-index "$skm_path" "$arg_path"
#   fi
# }
# 
# cmd_list() {
#   #if ! -v "$PREFIX"
#   #if ! (git -C "$PREFIX" 2>/dev/null); then
#   #  die "Error: '$PREFIX' is not a valid git directory. Run '$PROGRAM init' to initialize it."
#   #  exit
#   #fi
#   #tree ~/.skm/
#   local arg_path="${1-.}"
#   local arg_path_abs; arg_path_abs="$(realpath "$arg_path")"
#   local skm_path="$SKEL_PATH/$arg_path"
#   if [[ -d $skm_path ]]; then
#     realpath "$skm_path"
#     tree -aClI '.git' --noreport "$skm_path" | tail -n +2
#   elif [[ -f $skm_path ]]; then
#     ls -la "$skm_path"
#   elif [[ $skm_path == "$SKEL_PATH/" ]]; then
#     die "Error: skel manager is not initialized. Try '$PROGRAM init'."
#   else
#     die "Error: '$arg_path_abs' is not managed by skm."
#   fi
# }
# 
# case $1 in
#   diff) shift; die "Error: use either diff-export/dex/de or diff-import/dim/di" ;;
#   diff-export|dex|de) shift; cmd_diff "export" "$@";;
#   diff-import|dim|di) shift; cmd_diff "import" "$@";;
#   export|ex|e) shift; cmd_export "$@" ;;
#   import|im|i) shift; cmd_import "$@" ;;
#   git|g) shift; cmd_git "$@" ;;
#   #init) shift; cmd_init "$@" ;; # TODO require a name; create $SKEL_MANAGER_DIR/skels/<name>
#   #link) shift; cmd_link "$@" ;;
#   list|ls) shift; cmd_list "$@" ;;
#   pwd) shift; cmd_pwd ;;
#   watch) shift; cmd_watch "$@";;
#   #TODO skel-list -- lists directories in $SKEL_MANAGER_DIR/skels
#   #TODO skel-use -- links $SKEL_MANAGER_DIR/skels/current to skels/<name>
#   #TODO skel-cd -- change to the selected skel (or current by default); this may not be possible with bash
#   *) cmd_list "$@" ;;
# esac
