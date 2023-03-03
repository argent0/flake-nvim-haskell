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

    packages.x86_64-linux.default = pkgs.stdenv.mkDerivation {
      name = "nvim-haskell";
      src = ./.;
      buildInputs = with pkgs; [
        nvim-vimrc-code.packages.x86_64-linux.default
      ];
      installPhase = ''
        mkdir -p $out/etc/nvim
        cat \
        ${nvim-vimrc-code.packages.x86_64-linux.default.outPath}/etc/nvim/vimrc \
        ${./lua-start} \
        ${./treesitter.lua} \
        ${./lspconfig.lua} \
        ${./lua-end}  > $out/etc/nvim/vimrc
      '';
    };


    devShells.x86_64-linux.default = pkgs.mkShell {
      buildInputs = let
        vimrcPath = "${self.packages.x86_64-linux.default}/etc/nvim/vimrc";
        local-neovim = pkgs.neovim.override {
          configure = { # Additional plugins to be installed
          packages.myVimPackages = with pkgs.vimPlugins; {
            start = [
              vim-nix
              copilot-vim
              vim-surround
              nvim-lspconfig
              nvim-cmp
              cmp-nvim-lsp
              (nvim-treesitter.withPlugins (p: with p; [ haskell ]))
            ];
            opt = [ ];
          };
          customRC = builtins.readFile vimrcPath;
        };
      };
      in [
        pkgs.haskell-language-server
        pkgs.ghc
        pkgs.nodejs
        pkgs.stack
        local-neovim
      ];
    };

  };
}
