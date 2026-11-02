# Commands worth remembering

Every command below has `--help`. Own commands come from `scripts/` (see
`scripts/README.md`); aliases and functions are in `common/home.nix`.

## System

```sh
rebuild                        # nh os switch: apply the configuration
update                         # nh os switch --update: update inputs, then apply
nh os test                     # try a configuration without a boot entry
nh clean all --keep 5          # remove old generations now (also runs weekly)
nix flake check                # lint and evaluate (in ~/nixos)
```

### Is an update worth it?

```sh
update-check                   # which inputs have newer commits (changes nothing)
nh os build --update           # in ~/nixos: build the update, list changed packages, don't switch
rebuild                        # then apply it ...
git checkout flake.lock        # ... or throw the update away
```

## Drives

```sh
mnt /dev/sdb1                  # mount a USB partition (udisksctl)
format-and-mount               # WIPE a drive, set it up as LUKS + Btrfs, mount it
umount-drive                   # unmount ~/mount and close the "micleh" LUKS mapper
partuuid                       # list partitions by PARTUUID
bfree                          # Btrfs space usage
bscrub && bscrubStatus         # check the file system for errors
```

## SSH and keys

```sh
create-ssh-key                 # ssh-keygen -t ed25519
ssh-permissions                # fix permissions in ~/.ssh
fingerprint                    # enroll a fingerprint (fprintd)
```

## Everyday helpers

```sh
ex archive.tar.gz              # extract almost any archive
l                              # eza -al --icons
bigFiles                       # sizes of everything below ., largest last
battery                        # battery details
sf                             # failed systemd units
journalInfo                    # errors of the current boot
programPath firefox            # where a command really lives in /nix/store
```
