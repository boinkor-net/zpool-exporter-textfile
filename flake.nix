{
  description = "A tool that reads zpool statuses (especially health) and writes them to a directory in prometheus textfile format.";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem
      (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          nativeBuildInputs = with pkgs; [ pkg-config zfs.dev ];
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
            src = ./.;
            cargoLock.lockFile = ./Cargo.lock;

            buildInputs = nativeBuildInputs;
          };

          defaultPackage = packages.zpool-exporter-textfile;
        }) // {
      nixosModules.zpool-exporter-textfile = import ./nixos { flake = self; };
    };
}
