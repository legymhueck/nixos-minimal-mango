# Repository Guide for Agents

Minimal NixOS desktop (MangoWM + Noctalia) for one laptop (host `nixbox`, user `m`): one root flake, shared `common/`, the desktop in `nixos-mango/`, local packages in `pkgs/`, scripts in `scripts/`, installer `install.sh`. README.md has the full layout.

## How it fits together

- `nixosConfigurations.nixbox` = `nixbox-mango`. A real `nixbox-mango` exists only if `nixos-mango/hardware-configuration.nix` exists (the flake adds it; the one committed under `nixos-mango/` belongs to this machine). The `-eval` twin uses a `/dev/null` stand-in: for checks only, never deploy.
- Module arguments `inputs` and `vars` (`common/vars.nix`) come from `specialArgs`/`extraSpecialArgs`; never `import` vars.nix in modules.
- `common/` = system + Home Manager base; `nixos-mango/` = desktop specifics.
- One `pkgs` everywhere (`useGlobalPkgs`); the overlay for it lives in `common/base.nix`.
- One spot for applications: free and unfree nixpkgs applications go into `common/apps.nix`; unfree ones also need a pname entry in the allowlist in `common/base.nix` (empty at the moment). The browser itself is `programs.firefox` in `common/firefox.nix`.
- One spot for own flakes: `pkgs/default.nix` (`callPackage` style) — no active entries at the moment; e.g. Double Commander instead comes from nixpkgs itself (`common/apps.nix`, the configuration in `dotfiles/`).
- No install stages: the installer sets up everything in one run (`profile` = `mango`, written by install.sh).

## Invariants

- `system.stateVersion` (in `common/base.nix`) and `home.stateVersion` stay `26.05`.
- No `inputs.noctalia.inputs.nixpkgs.follows` (the Noctalia Cachix cache needs its own pin).
- Unfree packages only via the explicit allowlist in `common/base.nix` (names as `lib.getName` returns them); keep it explicit instead of `allowUnfree = true`.
- Mango login: LUKS passphrase = user password. greetd autologin (`initial_session`) at boot only, tuigreet afterwards. Never set an empty password; root stays locked.
- zram only, no swap file. `programs.nh` cleans; never also enable `nix.gc`.
- Cursor: set once as `nixbox.cursor` in `nixos-mango/configuration.nix`; `desktop.nix` reads it via `osConfig` for dconf, Mango, `gtk.cursorTheme` and the `XCURSOR_*` session variables.
- `install.sh` copies the whole checkout and commits with `git add -A` (`.gitignore` covers `result*`).

## Workflows

```sh
nix flake check   # statix, deadnix, shellcheck + evaluation of all outputs
nix eval .#nixosConfigurations.nixbox-mango-eval.config.system.build.toplevel.drvPath
nix eval .#nixosConfigurations.nixbox-mango.config.system.build.toplevel.drvPath        # the real system
nix build .#<pkg> # a local package from pkgs/
nix fmt           # nixfmt; CI fails on unformatted files
```

Flakes only see git-tracked files: `git add` new files before evaluating. Users rebuild with `nh os switch`.

## Making changes

- Shared things go in `common/`; the variant dir only holds desktop-specific things.
- New or renamed nix file: update the `imports` and the file checks in `install.sh`.
- New nixpkgs application (free or unfree): `common/apps.nix` — that is the single spot; allowlist entry in `common/base.nix` when unfree.
- New own package: `pkgs/<name>/package.nix` (`callPackage` style, `meta.platforms`), a line in `pkgs/default.nix`, referenced from `common/apps.nix`, allowlist entry if unfree. Prefer wrapping a finished package (`symlinkJoin`) over `overrideAttrs`, which forces a local build.
- New script: `scripts/<name>.sh` plus a `mkScript` line with its runtime dependencies in `common/scripts.nix`.
- New user-facing command, alias or script: add it to `docs/tips/commands.md`.
- Firefox: `profiles.default.settings` plus `policies` in `common/firefox.nix`.
