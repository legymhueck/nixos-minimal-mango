{
  vars,
  ...
}:

{
  imports = [
    ./firefox.nix
    ./apps.nix
    ./scripts.nix
  ];

  # Home Manager base settings (the desktop is in nixos-mango/).

  home.username = vars.user;
  home.homeDirectory = "/home/${vars.user}";
  home.stateVersion = "26.05";

  fonts.fontconfig.enable = true;

  # The defaults are ~/Desktop, ~/Documents, ..., ~/Projects.
  xdg.userDirs = {
    enable = true;
    createDirectories = true;
  };

  # --- shell ---
  home.sessionPath = [ "$HOME/.local/bin" ];
  home.sessionVariables = {
    EDITOR = "vim";
  };

  programs.bash = {
    enable = true;
    enableCompletion = true;
    shellAliases = {
      # rebuild: nh finds the flake via programs.nh.flake (~/nixos)
      rebuild = "nh os switch";
      update = "nh os switch --update";
      l = "eza -al --icons";
      battery = "acpi --battery --details";
      bigFiles = "du -ahx . | sort -h | nl";
      cpufreq = "watch grep \"cpu MHz\" /proc/cpuinfo";
      fingerprint = "sudo fprintd-enroll \"$(whoami)\"";
      grep = "grep --color=auto";
      gs = "git status";
      journalInfo = "journalctl -p 3 -xb";
      mnt = "udisksctl mount -b ";
      partuuid = "ls -l /dev/disk/by-partuuid";
      polkitStatus = "pgrep -af polkit";
      sf = "sudo systemctl --failed";
      sstart = "sudo systemctl start";
      sstat = "sudo systemctl status";
      create-ssh-key = "ssh-keygen -t ed25519";

      # Btrfs
      bbalance = "sudo btrfs balance start /";
      bbalanceStatus = "sudo btrfs balance status /";
      bdefrag = "sudo btrfs filesystem defragment -r /";
      bfree = "sudo btrfs filesystem usage /";
      bscrub = "sudo btrfs scrub start /";
      bscrubStatus = "sudo btrfs scrub status /";
    };
    initExtra = ''
      # Cursor shape
      printf '\e[34 q'

      programPath() {
        readlink -e "$(which "$1")"
      }

      umount-drive() {
        local mnt="''${1:-$HOME/mount}"
        local map="''${2:-micleh}"
        mnt="''${mnt/#\~/$HOME}"
        if mountpoint -q "$mnt"; then
          sudo umount "$mnt"
          echo "Unmounted $mnt"
        else
          echo "Not mounted: $mnt"
        fi
        if [ -e "/dev/mapper/$map" ]; then
          sudo cryptsetup close "$map"
          echo "Closed /dev/mapper/$map"
        else
          echo "Mapper not open: $map"
        fi
      }

      # Archive extractor
      ex() {
        if [ -f "$1" ]; then
          case "$1" in
            *.tar.bz2|*.tbz2) tar xjf "$1" ;;
            *.tar.gz|*.tgz) tar xzf "$1" ;;
            *.tar.xz|*.tar) tar xf "$1" ;;
            *.tar.zst) unzstd "$1" ;;
            *.bz2) bunzip2 "$1" ;;
            *.gz) gunzip "$1" ;;
            *.zip) unzip "$1" ;;
            *.Z) uncompress "$1" ;;
            *.7z) 7z x "$1" ;;
            *) echo "'$1' cannot be extracted via ex()" ;;
          esac
        else
          echo "'$1' is not a valid file"
        fi
      }
    '';
  };

  programs.starship = {
    enable = true;
    settings = builtins.fromTOML (builtins.readFile ../dotfiles/config/.config/starship.toml);
  };
  programs.zoxide.enable = true;
  programs.eza = {
    enable = true;
    icons = "auto";
  };

  programs.git = {
    enable = true;
    ignores = [
      "*.backup*"
      "*.swp"
      "*.swo"
      "*~"
      ".DS_Store"
    ];
    settings = {
      user = {
        name = "MicLeh";
        email = "micleh@proton.me";
      };
      init.defaultBranch = "main";
      pull.rebase = true;
    };
  };
  # GitHub login via `gh auth login`; also installs the git credential helper.
  programs.gh = {
    enable = true;
    gitCredentialHelper.enable = true;
  };

  programs.foot = {
    enable = true;
    settings = {
      main.font = "JetBrains Mono NL:size=13";
      main.include = "~/.config/foot/themes/noctalia";
      scrollback.lines = 10000;
    };
  };

  # --- files ---
  xdg.configFile = {
    "doublecmd/doublecmd.xml".source = ../dotfiles/doublecmd/.config/doublecmd/doublecmd.xml;
    "mc/ini".source = ../dotfiles/mc/.config/mc/ini;
    "mc/panels.ini".source = ../dotfiles/mc/.config/mc/panels.ini;
    "user-dirs.locale".source = ../dotfiles/config/.config/user-dirs.locale;
  };
}
