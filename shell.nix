with import <nixpkgs> {};
let
  my_vim = callPackage ./nix/vim/vim.nix {};
in pkgs.mkShell {
  name = "skm-shell";
  nativeBuildInputs = [ git my_vim fzf tree shellcheck ];
  shellHook = ''
    set -o vi
    alias skm='$(realpath ./skel-manager.sh) '
  '';
}
