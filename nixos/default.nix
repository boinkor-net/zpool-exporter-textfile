{ pkgs, lib, config, ... }:
let
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
        type = types.str;
        default = "5min";
      };

      user = mkOption {
        description = "User to use for polling the zpool status.";
        type = with types; nullOr str;
        default = "zpool-exporter-textfile";
      };

      zfsPackage = mkOption {
        description = "ZFS package with whose zpool command to collect statuses.";
        default = pkgs.zfs;
      };

      exporterPackage = mkOption {
        description = "Package containing the zpool-exporter-textfile that we should use to collect statuses.";
        default = pkgs.zpool-exporter-textfile;
      };
    };
  };

  config = lib.mkIf cfg.enable
    (lib.mkMerge [
      (lib.mkIf (cfg.user == "zpool-exporter-textfile")
        {
          users.users.zpool-exporter-textfile = {
            description = "Prometheus data gatherer for zpools health";
            isSystemUser = true;
          };
        })
      {
        systemd.services.zpool-exporter-textfile = {
          path = [ cfg.zfsPackage ];
          script = ''
            ${cfg.exporterPackage}/bin/zpool-exporter-textfile -o $STATE_DIRECTORY/zpool_statuses.prom
          '';
          serviceConfig = {
            Type = "oneshot";
            StateDirectory = "zpool-exporter-textfile";
            StateDirectoryMode = "0755";
            User = cfg.user;
          };
        };

        systemd.timers.zpool-exporter-textfile = {
          wantedBy = [ "timers.target" ];
          partOf = [ "zpool-exporter-textfile.service" ];
          timerConfig = {
            OnUnitActiveSec = cfg.regenerateInterval;
            Persistent = true;
          };
        };
      }
    ]);
}
