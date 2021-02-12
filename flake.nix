{
  description = "A tool that reads zpool statuses (especially health) and writes them to a directory in prometheus textfile format.";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    naersk.url = "github:nmattia/naersk";
  };
  outputs = { nixpkgs, flake-utils, naersk, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        naersk-lib = naersk.lib."${system}";
      in
      {
        devShell =
          pkgs.mkShell {
            nativeBuildInputs = with pkgs; [ pkgconfig zfs ];
            shellHook = ''
            '';
          };

        defaultPackage = naersk-lib.buildPackage {
          src = ./.;
        };
      });
}
