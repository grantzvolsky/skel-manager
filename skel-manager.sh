#!/usr/bin/env bash

cmd_init() {
  echo init
  git init ~/.skm
}

cmd_add() {
  # TODO if not exists
  cp --parents $(realpath $1) ~/.skm/
  ln -sfn ~/.skm/$(realpath $1) $1
}

cmd_list() {
  tree ~/.skm/
}

case $1 in
  init) shift; cmd_init "$@" ;;
  add) shift; cmd_add "$@" ;;
  *) shift; cmd_list "$@" ;;
esac
