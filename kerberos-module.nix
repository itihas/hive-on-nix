{ config, lib, pkgs, ... }:

with lib;

{
  # to be submitted to nixpkgs.
  options.services.kerberos_server = {
    primary = mkEnableOption "is this kdc server the primary server? Setting this to true will run kprop replicator with target kdcs specified in `config.services.kerberos_server.kdcs` every 2 minutes. Setting it to false will instead run the kpropd listener.";
    admin_server = mkOption {
      type = types.str;
      default = null;
      description = "fighting the deprecation of kerberosAdminServer by stopgap measures that ought to become ways of making node lists from flake based deployments at some point";
    };
    kdcs = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "list of kdcs that are not the admin server";
    };
  };

  config = mkMerge [
    {
      krb5 = {
        enable = true;
        realms = lib.genAttrs (lib.attrNames config.services.kerberos_server.realms) (x: {
          admin_server = config.services.kerberos_server.admin_server;
          kdc = config.services.kerberos_server.kdcs;
        });
      };
    }
    (mkIf config.services.kerberos_server.enable {
      systemd = mkMerge [
        (mkIf config.services.kerberos_server.primary {

          timers.kprop = {
            wantedBy = [ "multi-user.target" ];
            timerConfig = {
              Persistent = "true";
              OnBootSec = "1min";
              OnUnitActiveSec = "2min";
            };
          };

          services.kprop = {
            path = [ config.krb5.kerberos ];
            script = ''
              #!${pkgs.bash}/bin/bash

              kdb5_util dump /var/lib/krb5kdc/replica_datatrans

              for kdc in ${concatStringsSep " " config.services.kerberos_server.kdcs}
                do
                    kprop -f /var/lib/krb5kdc/replica_datatrans $kdc
                done

            '';
          };

          services.kadmind.environment.KRB5_KDC_PROFILE = pkgs.lib.mkForce
            (pkgs.writeText "kdc.conf" ''
              ${builtins.readFile config.environment.etc."krb5kdc/kdc.conf".source}
              	'');
        })

        (mkIf (!config.services.kerberos_server.primary) {
          services.kpropd = {
            description = "Kerberos replication listener";
            wantedBy = [ "multi-user.target" ];
            preStart = ''
              mkdir -m 0755 -p /var/lib/krb5kdc
            '';
            serviceConfig.ExecStart = "${config.krb5.kerberos}/bin/kpropd -P 754 -D -s /etc/krb5.keytab --pid-file=/run/kpropd.pid"; # remember that this means we need to create krb5.keytab. TODO write the init script that does this.
            restartTriggers = config.systemd.services.kadmind.restartTriggers;
            environment = config.systemd.services.kdc.environment;
          };
        })
      ];
    })
  ];

}
