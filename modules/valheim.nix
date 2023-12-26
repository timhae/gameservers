{ config, lib, pkgs, inputs, outputs, ... }:
# TODO: move into gameservers
let cfg = config.setup.service.valheim;
in
with lib; {
  options = { setup.service.valheim.enable = mkEnableOption "enable valheim"; };
  config = mkIf cfg.enable {
    systemd.services.valheim = {
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecStartPre = ''
          ${pkgs.steamcmd}/bin/steamcmd \
            +force_install_dir $STATE_DIRECTORY \
            +login anonymous \
            +app_update 896660 \
            +quit
        '';
        ExecStart = ''
          ${pkgs.glibc}/lib/ld-linux-x86-64.so.2 ./valheim_server.x86_64 \
            -name "derservername" \
            -port 2456 \
            -password "${outputs.gitcrypt.valheim.PW}" \
            -world "Florian" \
            -public 1
        '';
        Restart = "always";
        StateDirectory = "valheim";
        User = "valheim";
        WorkingDirectory = "/var/lib/valheim";
      };
      environment = { LD_LIBRARY_PATH = "linux64:${pkgs.glibc}/lib"; };
    };
    users.users.valheim = {
      home = "/var/lib/valheim";
      isNormalUser = true;
    };
    networking.firewall = {
      allowedTCPPortRanges = [{
        from = 2456;
        to = 2458;
      }];
      allowedUDPPortRanges = [{
        from = 2456;
        to = 2458;
      }];
    };
  };
}
