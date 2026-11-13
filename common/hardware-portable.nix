{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.nixbox;
  batteryPath = "/sys/class/power_supply/BAT0";
in
{
  # Hardware part for a system that lives on a USB stick and boots on any
  # x86_64 UEFI PC (Intel or AMD). The generated hardware-configuration.nix only
  # knows the machine the installer ran on; everything another PC may need is
  # added here. Shared system settings live in base.nix.

  options.nixbox.batteryThresholds = lib.mkOption {
    type = lib.types.nullOr (
      lib.types.submodule {
        options = {
          start = lib.mkOption { type = lib.types.int; };
          end = lib.mkOption { type = lib.types.int; };
        };
      }
    );
    default = null;
    example = {
      start = 70;
      end = 80;
    };
    description = "Battery charge limits (ThinkPad-style sysfs files, skipped where missing). null leaves the firmware default.";
  };

  config = {
    # --- boot from whatever controller the stick is plugged into ---
    boot.initrd.availableKernelModules = [
      "xhci_pci"
      "ehci_pci"
      "uas"
      "usb_storage"
      "usbhid"
      "hid_generic"
      "sd_mod"
      "thunderbolt"
      "nvme"
      "ahci"
    ];
    boot.kernelModules = [
      "kvm-intel"
      "kvm-amd"
    ];

    # --- firmware and microcode for Intel and AMD (only the matching one loads) ---
    hardware.enableRedistributableFirmware = true;
    hardware.cpu.intel.updateMicrocode = true;
    hardware.cpu.amd.updateMicrocode = true;
    hardware.firmware = [ pkgs.sof-firmware ]; # Intel laptop audio

    # --- graphics: Mesa (AMD/Intel/nouveau) from hardware.graphics; Intel video
    #     decoding on top. No LIBVA_DRIVER_NAME: libva picks iHD or radeonsi
    #     per machine.
    hardware.graphics.extraPackages = with pkgs; [
      intel-media-driver
      vpl-gpu-rt # QSV on Gen12+ (Tiger Lake and newer)
    ];

    # Fingerprint readers where present (fprintd is D-Bus activated, idle otherwise).
    services.fprintd.enable = true;

    # --- battery charge thresholds (opt-in: nixbox.batteryThresholds) ---
    systemd.services.battery-charge-threshold = lib.mkIf (cfg.batteryThresholds != null) {
      description = "Set battery charge thresholds";
      wantedBy = [ "multi-user.target" ];
      serviceConfig.Type = "oneshot";
      serviceConfig.RemainAfterExit = true;
      script = ''
        if [ -w ${batteryPath}/charge_control_start_threshold ]; then
          echo ${toString cfg.batteryThresholds.start} > ${batteryPath}/charge_control_start_threshold
        fi
        if [ -w ${batteryPath}/charge_control_end_threshold ]; then
          echo ${toString cfg.batteryThresholds.end} > ${batteryPath}/charge_control_end_threshold
        fi
      '';
    };
  };
}
