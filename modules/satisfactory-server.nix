{
  config,
  lib,
  pkgs,
  ...
}:
let
  steam-app = "1690800";
  cfg = config.services.satisfactory;
in
{
  imports = [
    ./steam.nix
  ];

  options.services.satisfactory = with lib; {
    enable = mkEnableOption ''
      Satisfactory Dedicated Server. The systemd unit is not started
      automatically. Also, do not forget to claim the server after you have
      started the service, see <help xlink:href="https://satisfactory.wiki.gg/wiki/Dedicated_servers#Claiming_the_Server_and_Starting_a_Game"/>.
    '';

    dataDir = mkOption {
      type = types.path;
      description = "Directory to store game server";
      default = "/var/lib/satisfactory";
    };

    port = mkOption {
      type = types.port;
      default = 7777;
      description = "Port for the server";
    };

    openFirewall = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to open ports in the firewall for the server";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.satisfactory = {
      # Install the game before launching.
      wants = [ "steam@${steam-app}.service" ];
      after = [ "steam@${steam-app}.service" ];

      serviceConfig = {
        ExecStart = lib.escapeShellArgs ([
          "/var/lib/steam-app-${steam-app}/FactoryServer.sh"
          "-Port=${toString cfg.port}"
        ]);
        PrivateTmp = true;
        Restart = "always";
        User = "satisfactory";
        WorkingDirectory = "~";
      };
      unitConfig = {
        StartLimitBurst = 2;
        StartLimitIntervalSec = 120;
      };
    };

    users.users.satisfactory = {
      isSystemUser = true;
      # Satisfactory puts save data in the home directory
      home = cfg.dataDir;
      createHome = true;
      homeMode = "750";
      group = "satisfactory";
    };

    users.groups.satisfactory = { };

    networking.firewall = lib.mkIf cfg.openFirewall {
      allowedTCPPorts = [ cfg.port ];
      allowedUDPPorts = [ cfg.port ];
    };
  };
}
