# After the install: the USB stick system

What to do once after `install.sh`, and what to keep in mind every day.
Commands are explained in `docs/tips/commands.md`.

## Before the first boot: the PC

- **Boot menu:** keep the new stick plugged in and pick it in the PC's boot
  menu (often F12, F8, F9 or Esc; the entry is usually "UEFI: <stick name>").
  The system never writes itself into the PC's firmware, so you choose it there
  every time; nothing on the host PC changes.
- **Secure Boot must be off.** systemd-boot is not signed. On PCs with
  Windows and BitLocker, switching Secure Boot off (or on again) makes Windows
  ask for the **BitLocker recovery key** at its next start. Have the key ready,
  or only use PCs where Secure Boot is already off.
- School and office PCs often block USB boot or the firmware setup with a
  password. Check that before you rely on a PC.
- UEFI only; legacy/CSM boot is not supported.

## First boot

1. Type the LUKS passphrase. The keyboard is German (`de-latin1`) at that
   prompt already.
2. The desktop starts without a login screen. The same password unlocks the
   lock screen and `sudo`.
3. Network: the Noctalia bar or `nmtui`. Wi-Fi networks are stored on the stick
   and follow you to every PC.
4. Optional: `sudo tailscale up` (Tailscale is enabled).

## The configuration in `~/nixos`

The installer copied the repo with `.git` and committed the generated
`nixos-mango/hardware-configuration.nix` as user "Installer".

```sh
cd ~/nixos
git remote add origin <url-of-this-repo>   # if not set yet
gh auth login                               # below
git push                                    # keeps the hardware config safe
```

`~/nixos` is this stick's system. Clone the big repo `nixos` somewhere else
(below), never over `~/nixos`.

## GitHub and the repos

```sh
gh auth login            # GitHub.com, HTTPS, log in with the browser
mkdir -p ~/GitHub && cd ~/GitHub
gh repo clone <owner>/unterricht
gh repo clone <owner>/nixos
```

The git name and e-mail come from `common/home.nix`. For SSH instead of HTTPS:
`create-ssh-key`, add the public key on GitHub, then `ssh-permissions`.

## The agents

Each one logs in once. The tokens live in your home folder on the encrypted
stick.

| Agent | First start | Notes |
| --- | --- | --- |
| Claude Code | `claude`, then log in through the browser | Updates come with `update`, not from the agent itself |
| GitHub Copilot CLI | `copilot`, then `/login` | Needs a Copilot plan on the GitHub account |
| opencode | `opencode auth login` | Pick the provider(s) you want |

Start agents inside the repo folder (`cd ~/GitHub/unterricht && claude`); each
repo's `AGENTS.md` / `CLAUDE.md` tells them the rules.

### Claude in the browser (optional)

The Claude browser agent runs only in a Chromium browser, so ungoogled-chromium
is installed next to Firefox. It has no Chrome Web Store:

1. In Chromium open `chrome://flags/#extension-mime-request-handling` and set
   it to **Always prompt for install**, then restart Chromium.
2. Open the Claude extension's page in the Chrome Web Store and download the
   extension, or install it from a `.crx` file. Chromium then asks to install it.
3. Extensions are not updated automatically; repeat this now and then.

Firefox stays the default browser for everything else.

### VSCodium

`codium .` in a repo folder (VSCodium is the free build of VS Code; the repo
unterricht's `.vscode/` settings apply as usual). The extensions (Claude, Java, Python, Typst,
Markdown, Marp, Nix) come from `common/apps.nix`; add new ones there instead of
installing them by hand, so they survive a reinstall.

## Tools in the repos

- **unterricht:** `_tools/html-bauen.sh`, `_tools/pdf-bauen.sh`,
  `typst compile --root . <datei.typ>`, `python _tools/diagramme-bauen.py` and
  `javac` (JDK 21 with JavaFX) work without further setup. The Typst layout's
  fonts (Carlito, JetBrains Mono NL) are installed; check with
  `fc-list | grep -i -e carlito -e "mono nl"` if a PDF looks different.
- **Python units with `pyproject.toml`** (pygame-ce, ...): `uv sync`, then
  `uv run main.py`. uv downloads Python 3.14 (`.python-version`) and the wheels
  itself; they run because `programs.nix-ld` is enabled. If a wheel complains
  about a missing `lib*.so`, add the library to `programs.nix-ld.libraries` in
  `common/base.nix` and `rebuild`.
- **nixos:** `nix flake check`, `nix fmt`. With an `.envrc` that holds
  `use flake`, run `direnv allow` once and the repo's dev shell loads on `cd`.

## Every day

- **Shut down before you unplug.** Pulling the stick while the system runs, or
  while it is suspended, can damage the file system. There is no hibernation.
- **Logs are gone after a reboot** (the journal is kept in RAM to spare the
  flash). Look at a problem before you restart: `journalInfo`, `sf`.
- **There are no snapshots.** Commit and push often; a stick can fail without
  warning. Only the repos on GitHub are safe. Keep `~/nixos` pushed too: with
  it, a new stick is one `install.sh` run away. Agent logins and SSH keys have
  to be set up again after a reinstall.
- **Updates:** `update` (all inputs) or `rebuild` (only apply changes). Claude
  Code, the Copilot CLI and the Claude VSCodium extension are packaged locally on each update, which
  takes longer than the cached packages. opencode is not in the binary cache
  either: after an update that changes it, it is built on the stick (about
  4 minutes: download plus bundling, nothing is compiled). Old generations are
  removed weekly.
- **Firefox keeps its cache in RAM** (to spare the flash), so pages load from
  the network again after a restart. The session is saved every minute: after a
  crash, the last minute of tabs may be missing.
- **Space:** check with `bfree`. The system needs about 15-20 GB; the rest is
  yours.
- **Battery limits** (ThinkPads) are off by default; enable them with
  `nixbox.batteryThresholds` in `nixos-mango/configuration.nix` if this stick
  mostly runs on one laptop.

## Sticks installed before 2026-11-17

The hostname changed from `nixbox` (the same as the main system) to `nixstick`.
Once, on the stick:

```sh
cd ~/nixos && git pull && nh os switch -H nixstick
```

Plain `rebuild` does not work for this step: it looks up the old hostname.
Afterwards `rebuild` and `update` work as usual. The same run also brings the
Firefox cache in RAM and builds opencode (a few minutes); log in to opencode
once with `opencode auth login`.

Tailscale: the stick keeps its Tailscale login, so its device normally just
shows the new name. Check `tailscale status` and the admin console; remove an
old `nixbox`/`nixbox-1` entry only if it is a second, offline device, never
the stick itself.

## If it does not boot

- No entry in the boot menu: Secure Boot is still on, or the PC boots legacy
  only.
- Stuck before the passphrase prompt on an unusual PC: try another USB port
  (USB 3 directly on the board, no hub).
- Black screen after the passphrase on a PC with an NVIDIA card: the free
  nouveau driver is used; there is no NVIDIA driver on the stick.
- An update broke something: pick an older generation in the systemd-boot menu
  (it shows the last 10), then `git checkout` the previous state in `~/nixos`
  and `rebuild`.
