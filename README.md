# NixOS

Personal, reproducible NixOS workstation configuration: a minimal MangoWM desktop with Home Manager, shared dotfiles, local packages and a single-step installer.

## Layout

| Path | Purpose |
| --- | --- |
| `flake.nix`, `flake.lock` | Single entry point, all inputs pinned. `nixosConfigurations.nixbox` is an alias for `nixbox-mango`; both exist only where `nixos-mango/hardware-configuration.nix` exists (the `-eval` twin with a `/dev/null` stand-in is for CI and `nix eval`, never deploy). Also exports the own packages (`nix build .#<pkg>`, none active — see `pkgs/`), a dev shell with the linters (`nix develop`) and the formatter |
| `profile` | Written by the installer (`mango`); which configuration `nixbox` builds |
| `common/` | `vars.nix` (user, host, Btrfs mounts), `base.nix` (system + essential CLI tools + unfree allowlist), `hardware-intel-laptop.nix` (Intel/ThinkPad specifics), `home.nix` (shell, git, starship, ...), `apps.nix` (the single spot for applications, free and unfree), `firefox.nix` (browser), `scripts.nix` |
| `nixos-mango/` | MangoWM + Noctalia: `configuration.nix` (Mango system side), `desktop.nix` (Mango/Noctalia Home Manager), `home.nix` (qt5ct/qt6ct theming, MIME defaults), `hardware-configuration.nix` |
| `wallpapers/` | Noctalia wallpaper source (`desktop.nix` points to `~/nixos/wallpapers`); `minimal-dark.png` is self-generated, no license restrictions |
| `dotfiles/` | Files that Home Manager links (doublecmd, mc, starship) |
| `pkgs/` | One spot for own flake packages (none active at the moment — entries for bibox, cornelsen, doublecmd, flaci, hylki, logseq, mtplayer, revpdf are kept commented out), added to `pkgs` by an overlay |
| `scripts/` | Shell scripts, installed as commands by `common/scripts.nix` |
| `install.sh` | Disk-wiping installer for the NixOS minimal ISO: installs everything (browser, applications, local packages) in one step |
| `docs/tips/` | Handouts; `docs/tips/commands.md` is a cheat sheet of everyday commands |
| `.github/workflows/` | CI: format, lint and evaluation |

## Install

Boot the NixOS minimal ISO (UEFI), connect to the network (`nmtui`), then:

```sh
git clone <your-repo-url> nixos
cd nixos
lsblk                                 # identify the target disk
sudo ./install.sh /dev/nvme0n1        # MangoWM + Noctalia
reboot
```

The script copies the complete checkout (with `.git`) to `~/nixos`, so it is a working clone afterwards (set the remote or keep it local). It **erases the whole disk** after you type `YES`, and refuses disks with mounted partitions (the installer stick). It creates GPT/EFI, LUKS2 and Btrfs subvolumes (`@`, `@home`, `@nix`, `@log`, zstd) and installs. A temporary swap file is used only during the install and deleted at the end; the installed system uses zram.

The script asks for **one password**. It becomes the LUKS passphrase and the password of `m`. Root login is disabled (use `sudo`).

Everything comes from the binary caches — the applications and system packages from cache.nixos.org, the Noctalia shell from its Cachix cache. Nothing is compiled during the install.

## Login

1. Power on, type the disk passphrase.
2. The desktop starts by itself, no login screen (boot only; after a logout or compositor crash tuigreet asks for the password).
3. The lock screen asks for the same password.

So there is exactly one password.

### Changing the password

The disk passphrase and the account password must stay identical:

```sh
sudo cryptsetup luksChangeKey /dev/disk/by-partlabel/nixos
passwd
```

## Daily use

```sh
nh os switch            # alias: rebuild. Apply the configuration
nh os switch --update   # alias: update. Update all inputs, then apply
nh os test              # activate without a boot entry
```

Old generations are removed weekly (`programs.nh.clean`, keeps 5 and 14 days). Check with `nix flake check` (lint and evaluation of all outputs) and `nix eval .#nixosConfigurations.nixbox-mango-eval.config.system.build.toplevel.drvPath` before pushing; CI runs the same. Format with `nix fmt`. `nix develop` gives a shell with statix, deadnix, nixfmt, shellcheck and shfmt.

### Notes for a future application or package

- A nixpkgs application (free or unfree) goes into `common/apps.nix` — the one spot for applications. Unfree ones additionally need their pname in the allowlist in `common/base.nix` (currently empty).
- A own package goes to `pkgs/<name>/package.nix`, is registered in `pkgs/default.nix` and referenced from `common/apps.nix`; unfree: also allowlist.
- A new user-facing command, alias or script: `docs/tips/commands.md`.
- Qt apps inherit the Noctalia palette from the qt5ct/qt6ct setup in `nixos-mango/`. Double Commander from nixpkgs is Qt5, so it is themed through qt5ct even though `QT_QPA_PLATFORMTHEME` is set to `qt6ct`.

## Reproducibility

- Every input is locked in `flake.lock`; `nix shell nixpkgs#...` and `<nixpkgs>` use the system's own nixpkgs revision (registry + `nixPath`).
- No package is pinned to another nixpkgs revision. If one breaks on unstable, add a `nixpkgs-stable` input and take only that package from it (overlay in `common/base.nix`); drop it again once unstable is cached.
- The Noctalia official and community plugin sources are pinned in `flake.lock` and exposed to Noctalia as immutable Nix store paths, so plugin code is not fetched at runtime.

## Notes

- Starting a fresh repo from these files (new `.git`): `git init && git add -A && git commit -m "Initial import"`. Flakes read working-tree files through git, so the files must be tracked before `nix flake check` / `nh os switch` work.
- `flake.lock` may contain entries for inputs no longer in `flake.nix` (hylki-src, revpdf-release were removed); they are ignored and pruned on the next `nix flake update`.
- `nixos-mango/hardware-configuration.nix` in the repo belongs to the current machine; the installer replaces it for a new one. Never deploy without the generated module of the target.
- Do not change `system.stateVersion` / `home.stateVersion` during routine updates.
- More detail: `AGENTS.md`.
