{ pkgs ? import (fetchTarball "https://github.com/NixOS/nixpkgs/archive/3590f02e7d5760e52072c1a729ee2250b5560746.tar.gz") {} }:
with pkgs;
let
  skm = pkgs.writeShellScriptBin "skm" (builtins.readFile ./skel-manager.sh); # TODO an independent derivation
  my_vim = callPackage ./nix/vim/vim.nix {};
in pkgs.mkShell {
  name = "skm-shell";
  nativeBuildInputs = [ fzf git inotify-tools my_vim shellcheck skm tree ];
  shellHook = ''
    set -o vi
  '';
}
