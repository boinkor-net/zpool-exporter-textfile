{
  description = "A tool that reads zpool statuses (especially health) and writes them to a directory in prometheus textfile format.";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    rust-overlay.url = "github:oxalica/rust-overlay";
    gitignore = {
      url = "github:hercules-ci/gitignore.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { self
    , nixpkgs
    , flake-utils
    , rust-overlay
    , gitignore
    , ...
    }:
    flake-utils.lib.eachDefaultSystem
      (system:
      let
        pkgs = (import nixpkgs { inherit system; overlays = [ (import rust-overlay) ]; });
        nativeBuildInputs = with pkgs; [ pkg-config zfs.dev ];
        rustPlatform = pkgs.makeRustPlatform {
          rustc = pkgs.rust-bin.stable.latest.minimal;
          cargo = pkgs.rust-bin.stable.latest.minimal;
        };
        inherit (gitignore.lib) gitignoreSource;
      in
      rec {
        devShell =
          pkgs.mkShell {
            inherit nativeBuildInputs;
          };

        packages.zpool-exporter-textfile = rustPlatform.buildRustPackage rec {
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
