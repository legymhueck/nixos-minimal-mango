{
  description = "minimal NixOS workstation configuration (MangoWM + Noctalia)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    mango = {
      url = "github:mangowm/mango";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # No nixpkgs.follows: the Noctalia Cachix cache only matches its own pin.
    noctalia.url = "github:noctalia-dev/noctalia";
    noctalia_official_plugins = {
      url = "github:noctalia-dev/official-plugins";
      flake = false;
    };
    noctalia_community_plugins = {
      url = "github:noctalia-dev/community-plugins";
      flake = false;
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      ...
    }@inputs:
    let
      inherit (nixpkgs) lib;
      vars = import ./common/vars.nix;
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      hardwareFile = ./nixos-mango/hardware-configuration.nix;
      hasHardware = builtins.pathExists hardwareFile;

      # Only for the `-eval` output: stands in for the generated hardware
      # module so the checkout evaluates without it (CI, `nix flake check`).
      # It is never part of the real configuration, so a missing hardware
      # module there fails loudly instead of producing an unbootable system.
      evaluationHardware = {
        fileSystems = lib.genAttrs vars.btrfsMounts (_: {
          device = "/dev/null";
          fsType = "btrfs";
        });
        boot.initrd.luks.devices.cryptroot.device = "/dev/null";
      };

      mkSystem =
        {
          evalOnly ? false,
        }:
        lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs vars; };
          modules = [
            ./nixos-mango/configuration.nix
            (if evalOnly then evaluationHardware else hardwareFile)
            home-manager.nixosModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                backupFileExtension = "bak";
                extraSpecialArgs = { inherit inputs vars; };
                users.${vars.user} = ./nixos-mango/home.nix;
              };
            }
          ];
        };

    in
    {
      formatter.${system} = pkgs.nixfmt-tree;

      nixosConfigurations =
        # The real configuration exists only where the generated hardware
        # module is present (the committed one belongs to the current machine).
        # `nixos-rebuild --flake .` / `nh os switch` look up the hostname.
        lib.optionalAttrs hasHardware { ${vars.host} = mkSystem { }; }
        # Evaluation-only twin for CI and `nix eval`; never deploy this.
        // {
          "${vars.host}-eval" = mkSystem { evalOnly = true; };
        };

      # Tools for working on this repository: `nix develop`.
      devShells.${system}.default = pkgs.mkShellNoCC {
        packages = with pkgs; [
          deadnix
          nixfmt
          shellcheck
          shfmt
          statix
        ];
      };

      checks.${system}.lint =
        pkgs.runCommandLocal "lint"
          {
            nativeBuildInputs = with pkgs; [
              deadnix
              shellcheck
              shfmt
              statix
            ];
          }
          ''
            cd ${self}
            statix check .
            deadnix --fail --exclude "**/hardware-configuration.nix" .
            shellcheck install.sh scripts/*.sh
            shfmt -d -i 2 -ci install.sh scripts/*.sh
            touch $out
          '';
    };
}
