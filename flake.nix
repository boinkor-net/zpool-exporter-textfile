{
  description = "A tool that reads zpool statuses (especially health) and writes them to a directory in prometheus textfile format.";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    naersk.url = "github:nmattia/naersk";
  };

  outputs = { self, nixpkgs, flake-utils, naersk, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        naersk-lib = naersk.lib."${system}";
        nativeBuildInputs = with pkgs; [ pkgconfig zfs ];
      in
      rec {
        devShell =
          pkgs.mkShell {
            inherit nativeBuildInputs;
          };

        packages.zpool-exporter-textfile = naersk-lib.buildPackage {
          inherit nativeBuildInputs;
          src = ./.;
        };

        defaultPackage = packages.zpool-exporter-textfile;

        apps.zpool-exporter-textfile = flake-utils.lib.mkApp {
          drv = defaultPackage;
        };

        overlay = final: prev: { zpool-exporter-textfile = defaultPackage; };

        nixosModules.zpool-exporter-textfile = import ./nixos;
      });
}
