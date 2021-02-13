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

        nixosModule = { config }:
          let
            lib = pkgs.lib;
            cfg = config.zpool-exporter-textfile;
          in
          {
            options = with lib; {
              zpool-exporter-textfile = {
                enable = mkOption {
                  description = "Enable the zpool exporter as a cron job task for all pools.";
                  type = types.bool;
                  default = false;
                };

                regenerateInterval = mkOption {
                  description = "Interval at which to poll the zpool status, in systemd.timer(5) format.";
                  type = types.string;
                  default = "5min";
                };

                user = mkOption {
                  description = "User to use for polling the zpool status. Defaults to a dynamically-generated user.";
                  type = types.string;
                  default = null;
                };

                zfsPackage = mkOption {
                  description = "ZFS package with whose zpool command to collect statuses.";
                  default = pkgs.zfs;
                };

                exporterPackage = mkOption {
                  description = "Package containing the zpool-exporter-textfile that we should use to collect statuses.";
                  default = self.packages.${system}.zpool-exporter-textfile;
                };
              };
            };

            config = lib.mkIf cfg.enable {
              systemd.services.zpool-exporter-textfile = {
                path = [ cfg.zfsPackage ];
                script = ''
                  ${cfg.exporterPackage}/bin/zpool-exporter-textfile -o $STATE_DIRECTORY/zpool_statuses.prom
                '';
                serviceConfig = lib.mkMerge [
                  {
                    Type = "oneshot";
                    StateDirectory = "zpool-exporter-textfile";
                  }
                  (lib.mkIf
                    cfg.user == null
                    {
                      DynamicUser = true;
                    })
                  (lib.mkIf cfg.user != null
                    {
                      User = cfg.user;
                    })
                ];
              };

              systemd.timers.zpool-exporter-textfile = {
                wantedBy = [ "timers.target" ];
                partOf = "zpool-exporter-textfile.service";
                timerConfig = {
                  OnUnitActiveSec = cfg.regenerateInterval;
                  Persistent = true;
                };
              };
            };
          };
      });
}
