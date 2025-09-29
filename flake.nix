# Needed to get to work 
# Downgrade lockfile
# npm i --lockfile-version 2 --package-lock-only

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
        name = "manage-my-damn-life";
        version = "0.8.1"; 
        
        build = pkgs.buildNpmPackage rec {
          pname = "${name}-build";
          inherit version;
          src = ./.;

          # Generate a new hash using:
          # nix develop
          # npm i --package-lock-only
          # prefetch-npm-deps package-lock.json
          npmDepsHash = "sha256-dALbxhzjm2IZva5PdgOYVMKUkvS2QibjoWOq1AWSJZ4=";

          nativeBuildInputs = with pkgs; [ cacert wget ];
          npmBuildScript = "build";

          installPhase = ''
            runHook preInstall

            mkdir $out
            cp -rv config $out/config
            cp -rv models $out/models
            cp -rv migrations $out/migrations
            cp -rv public $out/public
            cp -rv ./.next/standalone/* $out
            cp -rv ./.next/standalone/.next $out/.next
            cp -rv ./.next/static $out/.next/static
            cp -rv node_modules/dotenv $out/node_modules/dotenv 

            runHook postInstall
            '';
          #meta.mainProgram = "${pname}";

          # Add internet access to build phase by adding output hash
            #outputHashAlgo = "sha256";
            #outputHashMode = "recursive";
            #outputHash = "sha256-dALbxhzjm2IZva5PdgOYVMKUkvS2QibjoWOq1AWSJZ4=";
          #outputHash = pkgs.lib.fakeHash;
        };

        program = pkgs.stdenv.mkDerivation rec {
          pname = "${name}";
          inherit version;
          src = build;

          installPhase = ''
            mkdir -p $out/lib $out/bin
            cp -rv . $out/lib 
 
            cat > $out/bin/${pname} << EOF
            !/bin/sh
            mkdir -p /var/lib/${pname}
            cd /var/lib/${pname} 
            rm -rf lib || true
            cp -r $out/lib .

            cd lib
            export NODE_ENV=production
            export NEXT_PUBLIC_SECRET=mmdl
            ${pkgs.lib.getExe pkgs.nodejs} server.js
            EOF

            chmod +x $out/bin/${pname}
            '';
        };
      in { 
          packages.default = program;
          devShells.default = pkgs.mkShell {
            packages = with pkgs; [
              nodejs
              pkgs.prefetch-npm-deps # see server.nix
            ];
          };
        };
    };
}

