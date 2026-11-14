{ config, pkgs, ... }:

let
  # The same JDK as in ./apps.nix (JavaFX built in): jdtls compiles against it.
  jdk = pkgs.jdk21.override { enableJavaFX = true; };
in
{
  # Neovim next to VSCodium. Plugins and Tree-sitter grammars come from nixpkgs
  # (pinned by flake.lock, prebuilt in the cache, nothing compiles on the stick).
  # The Lua config lives in ../dotfiles/nvim and is linked out of the store, so
  # edits there apply on the next start of nvim without a rebuild.
  programs.neovim = {
    enable = true;
    viAlias = true;
    vimAlias = true;
    withRuby = false;
    withPython3 = false;

    plugins = with pkgs.vimPlugins; [
      # look and finding things
      tokyonight-nvim
      mini-nvim # icons, statusline, surround, pairs, text objects
      snacks-nvim # picker, explorer, terminal, lazygit
      which-key-nvim
      oil-nvim
      gitsigns-nvim
      (nvim-treesitter.withPlugins (
        p: with p; [
          bash
          css
          html
          java
          json
          lua
          markdown
          markdown_inline
          nix
          python
          toml
          typst
          yaml
        ]
      ))

      # language support
      nvim-lspconfig # server defaults for vim.lsp.enable()
      nvim-jdtls
      blink-cmp
      conform-nvim
      nvim-lint
      typst-preview-nvim
      render-markdown-nvim

      # AI (Claude Code and opencode run in a terminal split and talk to nvim)
      claudecode-nvim
      opencode-nvim
    ];

    # Language servers only nvim needs. Shared tools (ruff, tinymist, typst,
    # the JDK, marp-cli, lazygit) are in ./apps.nix so the shell has them too.
    extraPackages = with pkgs; [
      basedpyright
      copilot-language-server # unfree, allowlist in ./base.nix
      jdt-language-server
      lua-language-server
      markdownlint-cli2
      marksman
      nixd
    ];
    extraWrapperArgs = [
      "--set"
      "JAVA_HOME"
      "${jdk.home}"
    ];

    initLua = ''require("m")'';
  };

  xdg.configFile."nvim/lua/m".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nixos/dotfiles/nvim/lua/m";
}
