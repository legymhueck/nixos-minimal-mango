{ pkgs, ... }:

{
  # The single spot for applications, free and unfree: everything from the
  # nixpkgs applications and the local packages from ../pkgs that belongs on
  # the desktop. (The browser is configured in ./firefox.nix, system-wide CLI
  # tools in ./base.nix; desktop plumbing for Mango is in nixos-mango/.)
  #
  # Unfree applications also need a pname entry in the allowlist in ./base.nix
  # (see there).

  home.packages = with pkgs; [
    # --- free: command line essentials for the user profile ---
    bat
    btop
    fd
    fzf
    p7zip
    ripgrep
    unzip
    zip

    # --- free: Wayland helpers ---
    wl-clipboard

    # --- free: file manager (nixpkgs build, Qt5, cached; theme comes from
    #     Noctalia via qt5ct, configuration in ../dotfiles/doublecmd) ---
    doublecmd

    # --- desktop applications ---
    megasync
    opencode-desktop
    pwvucontrol
    # Second browser, only for the Claude browser agent (Claude in Chrome
    # needs a Chromium engine; it does not run in Firefox). No Web Store:
    # install the extension by hand. Firefox stays the default.
    ungoogled-chromium

    # --- coding agents (claude-code and github-copilot-cli are unfree) ---
    claude-code
    github-copilot-cli
    github-copilot-app
    opencode
    nodejs # npx for MCP servers the agents start

    # --- toolchain for the repo unterricht (its AGENTS.md and _tools/) ---
    pandoc # html-bauen.sh, pdf-bauen.sh
    typst # print layout, also docs in the repo nixos
    tinymist # Typst language server
    plantuml # diagramme-bauen.py (brings Graphviz)
    (python3.withPackages (
      ps: with ps; [
        markdownify
        pillow
        pygments
      ]
    ))
    uv # units with pyproject.toml/uv.lock
    ruff
    # Java 21 with JavaFX built in, like Liberica JDK Full on the school PCs:
    # javac checks of the JavaFX and Oberstufe code.
    (jdk21.override { enableJavaFX = true; })
    xvfb-run # headless runs of GUI programs

    # --- toolchain for the repo nixos (its dev shell has the same) ---
    deadnix
    nixfmt
    shellcheck
    shfmt
    statix
  ];

  # VSCodium (free build of VS Code) with the extensions for both repos; only
  # the Claude extension is unfree.
  programs.vscode = {
    enable = true;
    package = pkgs.vscodium;
    profiles.default.extensions = with pkgs.vscode-extensions; [
      anthropic.claude-code
      bbenoist.nix
      davidanson.vscode-markdownlint
      marp-team.marp-vscode
      ms-python.debugpy
      ms-python.python
      myriad-dreamin.tinymist
      redhat.java
      vscjava.vscode-java-debug
      vscjava.vscode-java-dependency
      vscjava.vscode-java-pack
      vscjava.vscode-java-test
      yzhang.markdown-all-in-one
    ];
  };
}
