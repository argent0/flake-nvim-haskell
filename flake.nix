{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    nvim-vimrc-code.url = "github:argent0/flake-nvim-vimrc-code";
  };

  outputs = { self, nixpkgs, nvim-vimrc-code }: 
  let
    pkgs = nixpkgs.legacyPackages.x86_64-linux;

  in {

    packages.x86_64-linux.vimrc = pkgs.stdenv.mkDerivation {
      name = "nvim-haskell";
      src = ./.;
      buildInputs = with pkgs; [
        nvim-vimrc-code.packages.x86_64-linux.vimrc
      ];
      installPhase = ''
        mkdir -p $out/etc/nvim
        cat \
        ${nvim-vimrc-code.packages.x86_64-linux.vimrc.outPath}/etc/nvim/vimrc \
        ${./lua-start} \
        ${./treesitter.lua} \
        ${./lspconfig.lua} \
        ${./lua-end}  > $out/etc/nvim/vimrc
      '';
    };

    lib = let
      vimrcPath = "${self.packages.x86_64-linux.vimrc}/vimrc";
      extraVimrcLines = builtins.readFile vimrcPath;
    in {
      version = "1.0.0";
      neovimForHaskell = {
        extraVimrcLines ? "",
        extraVimPlugins ? [ ],
      }: nvim-vimrc-code.lib.neovim {
        extraVimrcLines = extraVimrcLines;
        extraVimPlugins = with pkgs.vimPlugins; [
          vim-surround
          nvim-lspconfig
          nvim-cmp
          cmp-nvim-lsp
          (nvim-treesitter.withPlugins (p: with p; [ haskell ]))
        ] ++ extraVimPlugins;
      };
    };

    packages.x86_64-linux.default = self.lib.neovimForHaskell { };

  };
}
