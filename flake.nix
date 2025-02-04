{
  description = "A tool that reads zpool statuses (especially health) and writes them to a directory in prometheus textfile format.";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    flake-utils.url = "github:numtide/flake-utils";

    fenix.url = "github:nix-community/fenix";
    fenix.inputs.nixpkgs.follows = "nixpkgs";

    gitignore = {
      url = "github:hercules-ci/gitignore.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    fenix,
    gitignore,
    ...
  }:
    flake-utils.lib.eachDefaultSystem
    (system: let
      pkgs = import nixpkgs {inherit system;};
      nativeBuildInputs = with pkgs; [pkg-config zfs.dev];
      rustPlatform = pkgs.makeRustPlatform {
        inherit (fenix.packages.${system}.stable) cargo rustc;
      };
      inherit (gitignore.lib) gitignoreSource;
    in rec {
      devShells.default = pkgs.mkShell {
        inherit nativeBuildInputs;
      };

      formatter = pkgs.alejandra;

      packages.zpool-exporter-textfile = rustPlatform.buildRustPackage rec {
        pname = "zpool-exporter-textfile";
        version = (builtins.fromTOML (builtins.readFile ./Cargo.toml)).package.version;
        inherit nativeBuildInputs;
        src = gitignoreSource ./.;
        cargoLock.lockFile = ./Cargo.lock;
        doCheck = true;

        buildInputs = nativeBuildInputs;
      };

      packages.default = packages.zpool-exporter-textfile;
    })
    // {
      nixosModules.zpool-exporter-textfile = import ./nixos {flake = self;};
    };
}
