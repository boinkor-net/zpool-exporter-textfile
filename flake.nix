{
  description = "A tool that reads zpool statuses (especially health) and writes them to a directory in prometheus textfile format.";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    gitignore = {
      url = "github:hercules-ci/gitignore.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, flake-utils, gitignore, ... }:
    flake-utils.lib.eachDefaultSystem
      (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          nativeBuildInputs = with pkgs; [ pkgconfig zfs.dev ];
          inherit (gitignore.lib) gitignoreSource;
        in
        rec {
          devShell =
            pkgs.mkShell {
              inherit nativeBuildInputs;
            };

          packages.zpool-exporter-textfile = pkgs.rustPlatform.buildRustPackage rec {
            pname = "zpool-exporter-textfile";
            version = (builtins.fromTOML (builtins.readFile ./Cargo.toml)).package.version;
            inherit nativeBuildInputs;
            src = gitignoreSource ./.;
            cargoLock.lockFile = ./Cargo.lock;

            buildInputs = nativeBuildInputs;
          };

          defaultPackage = packages.zpool-exporter-textfile;
        }) // {
      nixosModules.zpool-exporter-textfile = import ./nixos { flake = self; };
    };
}
