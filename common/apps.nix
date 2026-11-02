{ pkgs, ... }:

{
  # The single spot for applications, free and unfree: everything from the
  # nixpkgs applications and the local packages from ../pkgs that belongs on
  # the desktop. (The browser is configured in ./firefox.nix, system-wide CLI
  # tools in ./base.nix; desktop plumbing for Mango is in nixos-mango/.)
  #
  # Unfree applications go into the last block and also need a pname entry in
  # the allowlist in ./base.nix (see there). None are installed at the moment.

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
    opencode
    opencode-desktop
    pwvucontrol
  ];
}
