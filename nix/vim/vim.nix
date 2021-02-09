#with import <nixpkgs> {};
{ vim_configurable, python3, pkgs }:
let
  my_vim_preferences = ''
    filetype indent off
    setl noai nocin nosi inde=
    set background=dark
    set expandtab shiftwidth=2 softtabstop=2 tabstop=2
    set hlsearch
    set noswapfile
    set nowrap

    nmap <C-w>- :sp<CR>
    nmap <C-w><Bar> :vsp<CR>
    nmap <C-h> <C-w>h
    nmap <C-j> <C-w>j
    nmap <C-k> <C-w>k
    nmap <C-l> <C-w>l
    nmap <S-Tab> :b#<CR>
    nnoremap <C-F7> :tabp<CR>
    nnoremap <C-F8> :tabn<CR>
    nnoremap <F7> :bp<CR>
    nnoremap <F8> :bn<CR>
    nnoremap <C-p> :FZF<CR>
    nnoremap <C-b> :Buffers<CR>
  '';

  ale_preferences = ''
    set signcolumn=yes
    hi clear SignColumn
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
      '' + my_vim_preferences + ale_preferences;

      packages.myVimPackage = with pkgs.vimPlugins; {
        start = [ ale LanguageClient-neovim fzf-vim fzfWrapper ];
      };
    };
  };
in my_vim
