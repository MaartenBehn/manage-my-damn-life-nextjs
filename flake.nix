{
  description = "manage-my-damn-life";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/release-25.05";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs =
    {
      nixpkgs,
      flake-parts,
      ...
    }@inputs:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "aarch64-linux"
        "x86_64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ];

      perSystem =
        {
        system,
        pkgs,
        ...
        }:
        let
          manage-my-damn-life = import ./nix {
            inherit pkgs;
            inherit system; 
          };
        in {
          packages.default = manage-my-damn-life.package;
          devShell = manage-my-damn-life.shell;
        };
    };
}

