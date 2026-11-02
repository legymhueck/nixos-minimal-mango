{ config, pkgs, ... }:

{
  imports = [
    ../common/home.nix
    ./desktop.nix
  ];

  # qt6ct styles the Qt apps (Double Commander) with the theme Noctalia
  # generates (templates for foot/gtk/qt are enabled in ./desktop.nix).
  home.packages = with pkgs; [ qt6Packages.qt6ct ];
  xdg.configFile."qt6ct/qt6ct.conf".text = ''
    [Appearance]
    color_scheme_path=${config.home.homeDirectory}/.config/qt6ct/colors/noctalia.conf
    custom_palette=true
    style=Fusion
  '';

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "x-scheme-handler/http" = [ "firefox.desktop" ];
      "x-scheme-handler/https" = [ "firefox.desktop" ];
      "text/html" = [ "firefox.desktop" ];
      "application/xhtml+xml" = [ "firefox.desktop" ];
      "application/x-extension-htm" = [ "firefox.desktop" ];
      "application/x-extension-html" = [ "firefox.desktop" ];
      "application/x-extension-shtml" = [ "firefox.desktop" ];
      "application/x-extension-xhtml" = [ "firefox.desktop" ];
      "application/x-extension-xht" = [ "firefox.desktop" ];
      "inode/directory" = [ "doublecmd.desktop" ];
    };
  };
}
