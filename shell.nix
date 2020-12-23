with import <nixpkgs> {};
let
  my_vim_preferences = ''
    set noswapfile
    set background=dark
    set expandtab tabstop=2 softtabstop=2 shiftwidth=2
    nnoremap <F7> :tabp<CR>
    nnoremap <F8> :tabn<CR>
    nnoremap <C-p> :FZF<CR>
    nnoremap <C-b> :Buffers<CR>
  '';

  my_vc = vim_configurable.override { python = python3; };

  my_vim = my_vc.customize {
    name = "e";
    vimrcConfig = {
      customRC = ''
         " let g:LanguageClient_serverCommands = { 'python': ['pyls'] }
         nnoremap <F5> :call LanguageClient_contextMenu()<CR>
         nnoremap <silent> gh :call LanguageClient_textDocument_hover()<CR>
         nnoremap <silent> gd :call LanguageClient_textDocument_definition()<CR>
         nnoremap <silent> gr :call LanguageClient_textDocument_references()<CR>
         nnoremap <silent> gs :call LanguageClient_textDocument_documentSymbol()<CR>
         " nnoremap <silent> <F2> :call LanguageClient_textDocument_rename()<CR>
         nnoremap <silent> gf :call LanguageClient_textDocument_formatting()<CR>
      '' + my_vim_preferences;

      packages.myVimPackage = with pkgs.vimPlugins; {
        start = [ LanguageClient-neovim fzf-vim fzfWrapper ];
      };
    };
  };
in pkgs.mkShell {
  name = "skm-shell";
  nativeBuildInputs = [ my_vim fzf tree ];
  shellHook = ''
    set -o vi
    alias skm='$(realpath ./skel-manager.sh) '
  '';
}
