# Repository Guide for Agents

Minimal NixOS desktop (MangoWM + Noctalia) on a USB stick that boots on any x86_64 UEFI PC (host `nixstick`, user `m`): one root flake, shared `common/`, the desktop in `nixos-mango/`, scripts in `scripts/`, installer `install.sh`. README.md has the full layout.

## How it fits together

- `nixosConfigurations.nixstick` exists only if `nixos-mango/hardware-configuration.nix` exists (the flake adds it; the one committed under `nixos-mango/` belongs to this machine). The `-eval` twin uses a `/dev/null` stand-in: for checks only, never deploy.
- Module arguments `inputs` and `vars` (`common/vars.nix`) come from `specialArgs`/`extraSpecialArgs`; never `import` vars.nix in modules.
- `common/` = system + Home Manager base; `nixos-mango/` = desktop specifics.
- One `pkgs` everywhere (`useGlobalPkgs`). No overlay and no local packages: everything comes from nixpkgs and its binary cache.
- One spot for applications: free and unfree nixpkgs applications go into `common/apps.nix`; unfree ones also need a pname entry in the allowlist in `common/base.nix` (claude-code, github-copilot-cli, copilot-language-server, the Claude VSCodium extension). The browser itself is `programs.firefox` in `common/firefox.nix`; ungoogled-chromium in `apps.nix` exists only for the Claude browser agent. foot is the only terminal; the editors are VSCodium via `programs.vscodium` (never `programs.vscode` with `package = vscodium`: that writes to VS Code's paths, VSCodium would not see the extensions) and Neovim via `programs.neovim` in `common/neovim.nix` (plugins from nixpkgs, Lua config in `dotfiles/nvim/lua/m`, linked out of the store so edits apply without a rebuild).
- Theming: Noctalia generates the GTK/Qt files (`theme.templates` in `nixos-mango/desktop.nix`). `nixos-mango/home.nix` points both qt5ct and qt6ct at the generated `colors/noctalia.conf`; `QT_QPA_PLATFORMTHEME=qt6ct` (`nixos-mango/configuration.nix`) covers both toolkits because qt5ct's plugin also registers the `qt6ct` key. Double Commander from nixpkgs is the **Qt5** build, so it needs qt5ct — installing only qt6ct leaves it on the default light palette.
- No install stages: the installer sets up everything in one run.

## Invariants

- `system.stateVersion` (in `common/base.nix`) and `home.stateVersion` stay `26.05`.
- No `inputs.noctalia.inputs.nixpkgs.follows` (the Noctalia Cachix cache needs its own pin).
- Unfree packages only via the explicit allowlist in `common/base.nix` (names as `lib.getName` returns them); keep it explicit instead of `allowUnfree = true`.
- Mango login: LUKS passphrase = user password. greetd autologin (`initial_session`) at boot only, tuigreet afterwards. Never set an empty password; root stays locked.
- zram only, no swap file. `programs.nh` cleans; never also enable `nix.gc`.
- USB stick: `boot.loader.efi.canTouchEfiVariables = false`; `time.hardwareClockInLocalTime = true` (it boots almost only on Windows PCs whose clock cannot be changed); hardware support stays generic (`common/hardware-portable.nix`, no vendor-only services or `LIBVA_DRIVER_NAME`). Spare the flash: journal and `/tmp` in RAM, no snapper, no `nix.optimise.automatic`. The installer mounts the ESP by device, never by label.
- `programs.nix-ld` stays enabled (uv-managed Python and wheels for the repo unterricht); extend `programs.nix-ld.libraries` on top of its default, never replace it.
- Cursor: set once as `nixbox.cursor` in `nixos-mango/configuration.nix`; `desktop.nix` reads it via `osConfig` for dconf, Mango, `gtk.cursorTheme` and the `XCURSOR_*` session variables.
- `install.sh` copies the whole checkout and commits with `git add -A` (`.gitignore` covers `result*`).

## Workflows

```sh
nix flake check   # statix, deadnix, shellcheck + evaluation of all outputs
nix eval .#nixosConfigurations.nixstick-eval.config.system.build.toplevel.drvPath
nix eval .#nixosConfigurations.nixstick.config.system.build.toplevel.drvPath        # the real system
nix fmt           # nixfmt; CI fails on unformatted files
```

Flakes only see git-tracked files: `git add` new files before evaluating. Users rebuild with `nh os switch`.

## Making changes

- Shared things go in `common/`; the variant dir only holds desktop-specific things.
- New or renamed nix file: update the `imports`. `install.sh` needs no file list: before wiping it evaluates `nixstick-eval`, which fails on any missing file.
- Shell scripts (`install.sh`, `scripts/`): `shfmt -i 2 -ci`, checked by the flake check `lint`.
- New nixpkgs application (free or unfree): `common/apps.nix` — that is the single spot; allowlist entry in `common/base.nix` when unfree.
- No own packages (`pkgs/` was removed 2026-11-17). If one is ever needed, copy it from `~/nixos/pkgs` together with its overlay line, but only if it does not compile for long. Prefer wrapping a finished package (`symlinkJoin`) over `overrideAttrs`, which forces a local build.
- New script: `scripts/<name>.sh` plus a `mkScript` line with its runtime dependencies in `common/scripts.nix`.
- New user-facing command, alias or script: add it to `docs/tips/commands.md`.
- Firefox: `profiles.default.settings` plus `policies` in `common/firefox.nix`.

## Relation to the main repo

- GitHub `legymhueck/nixstick` (renamed from `nixos-minimal-mango` on 2026-11-17; the old URL redirects). Sister repo of `~/nixos` (GitHub `legymhueck/nixos`, the full system on the internal SSD, host `nixbox`). This one is the minimal variant for a USB stick: only cached packages, generic hardware, flash-friendly settings. Ideas are often ported from there; check the invariants above before copying (no snapper, no `nix.optimise`, no `canTouchEfiVariables`, no install stages, no local builds).
- Differences on purpose: docs here are English Markdown (`docs/tips/`), not German Typst; applications live in one file (`common/apps.nix`), not in four stage lists; no `pkgs/`.
- Ported from the main repo on 2026-11-17: `shfmt` in the lint check, the evaluation preflight in `install.sh`, `actions/checkout` v7.0.1.

## Status (2026-11-17)

- CI was red since 2026-11-13: `3b9f7f8` failed on megasync (unfree, not allowlisted; removed in `bbdf8c3`), `8a9c1b3` on the unformatted `nixos-mango/hardware-configuration.nix`. Fixed together with two evaluation warnings (`services.journald.storage` renamed to `services.journald.settings.Journal.Storage`; `programs.vscode` with VSCodium replaced by `programs.vscodium`).
- `flake.lock` updated on 2026-11-17 (nixpkgs 2026-11-13, same revision as the main repo `~/nixos`). `nix flake check` passed, no warnings; the dry-run builds only configuration files, wrappers, initrd and kernel modules locally (plus Mango and the unfree wrappers on a fresh stick).
- Check CI after each push: `gh run list --limit 5`, failures with `gh run view <id> --log-failed`.
- Hostname `nixstick` since 2026-11-17 (was `nixbox`, the same as the main system: two `nixbox` devices in Tailscale, clashing SSH host keys). A stick installed before that needs once: `cd ~/nixos && git pull && nh os switch -H nixstick` (plain `rebuild` looks up the old hostname), then remove the stick's old `nixbox`/`nixbox-1` device in the Tailscale admin console.
