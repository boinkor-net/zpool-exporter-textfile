[![Build Status](https://circleci.com/gh/antifuchs/zpool-exporter-textfile.svg?style=svg)](https://circleci.com/gh/antifuchs/zpool-exporter-textfile) [![Docs](https://docs.rs/zpool-exporter-textfile/badge.svg)](https://docs.rs/zpool-exporter-textfile/) [![crates.io](https://img.shields.io/crates/v/zpool-exporter-textfile.svg)](https://crates.io/crates/zpool-exporter-textfile)

# zpool-exporter-textfile

This program can export metrics about the health of ZFS zpools into a text file that can be picked up by prometheus's node_collector via the textfile collector.

## Usage

You'll want to regularly run this program. It automatically collects data about all active zpools.

```
$ zpool-exporter-textfile -o .../zpool_stats.txt
```

## Installation

To build this, you need `libzfs`, as that's a compile time dependency. If you use nix, the included flake.nix will result in a binary that you can use.

### Use in a flake

You can use this in a flake like so (I hope!):

```nix
{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    zpool-exporter.url = "github:antifuchs/zpool-exporter-textfile";
  };

  outputs = { zpool-exporter, nixpkgs, ... }: {
    nixosConfigurations = {
      hostname = nixpkgs.lib.nixosSystem rec {
        system = "x86_64-linux";
        modules = [
          ./configuration.nix
          zpool-exporter.nixosModules.zpool-exporter-textfile
          {config, ...}: { zpool-exporter-textfile.enable = true; }
        ];
      };
    };
  };
}
```

## Example metrics

```txt
# HELP zpool_health_level Overall health level of a pool. 0 if unhealthy, 1 if healthy.
# TYPE zpool_health_level gauge
zpool_health_level{pool="bpool"} 1
zpool_health_level{pool="data"} 1
zpool_health_level{pool="rpool"} 1
# HELP zpool_health_state Health status (1 if the <pool> is at health <state>)
# TYPE zpool_health_state gauge
zpool_health_state{pool="bpool",state="Available"} 0
zpool_health_state{pool="bpool",state="Degraded"} 0
zpool_health_state{pool="bpool",state="Faulted"} 0
zpool_health_state{pool="bpool",state="Offline"} 0
zpool_health_state{pool="bpool",state="Online"} 1
zpool_health_state{pool="bpool",state="Removed"} 0
zpool_health_state{pool="bpool",state="Unavailable"} 0
zpool_health_state{pool="data",state="Available"} 0
zpool_health_state{pool="data",state="Degraded"} 0
zpool_health_state{pool="data",state="Faulted"} 0
zpool_health_state{pool="data",state="Offline"} 0
zpool_health_state{pool="data",state="Online"} 1
zpool_health_state{pool="data",state="Removed"} 0
zpool_health_state{pool="data",state="Unavailable"} 0
zpool_health_state{pool="rpool",state="Available"} 0
zpool_health_state{pool="rpool",state="Degraded"} 0
zpool_health_state{pool="rpool",state="Faulted"} 0
zpool_health_state{pool="rpool",state="Offline"} 0
zpool_health_state{pool="rpool",state="Online"} 1
zpool_health_state{pool="rpool",state="Removed"} 0
zpool_health_state{pool="rpool",state="Unavailable"} 0
```
