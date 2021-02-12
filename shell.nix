{ pkgs ? import (fetchTarball "https://github.com/NixOS/nixpkgs/archive/3590f02e7d5760e52072c1a729ee2250b5560746.tar.gz") {} }:
with pkgs;
let
  my_vim = callPackage ./nix/vim/vim.nix {};
in pkgs.mkShell {
  name = "skm-shell";
  nativeBuildInputs = [ my_vim git fzf tree shellcheck ];
  shellHook = ''
    set -o vi
    alias skm='$(realpath ./skel-manager.sh) '
  '';
}
