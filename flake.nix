{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    # musnix.url = "github:musnix/musnix";
    # musnix.inputs.nixpkgs.follows = "nixpkgs";
    # companion.url = "github:noblepayne/bitfocus-companion-flake";
    # companion.inputs.nixpkgs.follows = "nixpkgs";

    prettyswitch.url = "github:noblepayne/pretty-switch";
    prettyswitch.inputs.nixpkgs.follows = "nixpkgs";

    hyprland.url = "github:hyprwm/Hyprland";
    hyprland.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = {
    self,
    nixpkgs,
    prettyswitch,
    hyprland,
    ...
  }: {
    # Formatter (optional)
    formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.alejandra;

    nixosConfigurations = {
      rvbee = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          hyprland.nixosModules.default
          ./hosts/rvbee/system.nix
          ./hosts/rvbee/hardware-configuration.nix
          prettyswitch.nixosModules.default
        ];
        specialArgs = {
          inherit hyprland;
        };
      };
      installer = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          # Graphical ISO with Calamares (Plasma)
          (nixpkgs + "/nixos/modules/installer/cd-dvd/installation-cd-graphical-calamares-plasma6.nix")
          # Optional: add extra tools to the live ISO
          ({pkgs, ...}: {
            environment.systemPackages = with pkgs; [
              neovim
              git
              firefox
              btop
            ];
            nix.settings.experimental-features = ["nix-command" "flakes"];
            nixpkgs.overlays = [
              (final: prev: {
                calamares-nixos-extensions = prev.calamares-nixos-extensions.overrideAttrs (old: {
                  # Replace the config generation script
                  postInstall =
                    (old.postInstall or "")
                    + ''
                      cp ${./jank.py} $out/lib/calamares/modules/nixos/main.py
                    '';
                });
              })
            ];
          })
        ];
      };
    };
  };
}
