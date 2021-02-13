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
        default = pkgs.zpool-exporter-textfile;
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
        (lib.mkIf (cfg.user == null)
          {
            DynamicUser = true;
          })
        (lib.mkIf (cfg.user != null)
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
}
