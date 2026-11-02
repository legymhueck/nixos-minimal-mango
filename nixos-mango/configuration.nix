{
  lib,
  pkgs,
  config,
  inputs,
  vars,
  ...
}:
let
  # Cursor theme and size, defined once here (nixbox.cursor) and read back by
  # Home Manager (./desktop.nix) via osConfig.
  cursorTheme = config.nixbox.cursor.theme;
in
{
  # The generated hardware-configuration.nix is added by the flake.
  imports = [
    inputs.mango.nixosModules.mango
    ../common/base.nix
    ../common/hardware-intel-laptop.nix
  ];

  # nixbox.batteryThresholds = { start = 70; end = 80; };

  # --- Mango specific: the Noctalia binary cache (avoids compiling the shell) ---
  nix.settings = {
    extra-substituters = [ "https://noctalia.cachix.org" ];
    extra-trusted-public-keys = [
      "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
    ];
  };

  # --- desktop ---
  options.nixbox.cursor = {
    theme = lib.mkOption {
      type = lib.types.str;
      description = "Cursor theme name (installed below).";
    };
    size = lib.mkOption {
      type = lib.types.ints.positive;
      description = "Cursor size in pixels.";
    };
  };

  programs.mango.enable = true; # session entry, portals, polkit, Xwayland
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
      xdg-desktop-portal-wlr
    ];
  };
  nixbox.cursor = {
    theme = "Breeze_Hacked";
    size = 48;
  };
  environment.sessionVariables = {
    QT_QPA_PLATFORMTHEME = "qt6ct";
    GTK_THEME = "adw-gtk3-dark"; # adw-gtk3 is installed below
    XCURSOR_THEME = cursorTheme;
    XCURSOR_SIZE = toString config.nixbox.cursor.size;
    XCURSOR_PATH = [ "/run/current-system/sw/share/icons" ];
  };
  environment.systemPackages = with pkgs; [
    adw-gtk3
    breeze-hacked-cursor-theme
    xwayland
  ];

  # --- login: no login screen at boot ---
  # 1. You type the disk (LUKS) passphrase at boot.
  # 2. greetd logs the user in automatically (initial_session, boot only) and
  #    starts Mango.
  # 3. After a logout or compositor crash greetd shows tuigreet and asks for
  #    the password: an autologin there would hand an unlocked session to
  #    anyone who can crash the compositor of a locked laptop.
  services.greetd = {
    enable = true;
    settings = {
      initial_session = {
        command = "mango";
        inherit (vars) user;
      };
      default_session = {
        command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --cmd mango";
        user = "greeter";
      };
    };
  };
  systemd.services.greetd.serviceConfig.Type = "idle";
  systemd.services."getty@tty1".enable = false;
  systemd.services."autovt@tty1".enable = false;
}
