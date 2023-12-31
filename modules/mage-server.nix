{ config, lib, pkgs, ... }:
let
  cfg = config.services.mage-server;
in
with lib; {
  options.services.mage-server.enable = mkEnableOption "enable the x mage server";
  config = mkIf cfg.enable {
    systemd.services.mage-server = {
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" ];
      description = "X mage server";
      serviceConfig = {
        Type = "simple";
        ExecStart =
          "${self.packages.x86_64-linux.mage-server}/bin/mage-server";
        WorkingDirectory = "/var/lib/mage-server";
        StateDirectory = "mage-server";
        DynamicUser = true;
      };
    };
    networking.firewall = {
      allowedTCPPorts = [ 17171 17172 ];
      allowedUDPPorts = [ 17171 17172 ];
    };
  };
}
