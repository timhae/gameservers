{
  config,
  pkgs,
  lib,
  ...
}:
let
  # Set to {id}-{branch}-{password} for betas.
  steam-app = "896660";
  cfg = config.services.valheim;
in
{
  imports = [
    ./steam.nix
  ];

  options.services.valheim = with lib; {
    enable = mkEnableOption "Valheim server. The systemd unit is not started automatically";

    dataDir = mkOption {
      type = types.path;
      description = "Directory to store game server";
      default = "/var/lib/valheim";
    };

    port = mkOption {
      type = types.port;
      default = 2456;
      description = "Port for the server";
    };

    openFirewall = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to open ports in the firewall for the server";
    };

    passwordFile = mkOption {
      type = types.str;
      description = ''
        String of the path to a Systemd EnvironmentFile that exports the server
        password as $PASSWORD (e.g. `PASSWORD=supersecret`). The password will
        end up in the nix store and leak on the command line but at least it is
        not part of your plaintext config in git.
      '';
    };

    serverName = mkOption {
      type = types.str;
      description = "Name of the server.";
      default = "customserver";
    };

    worldName = mkOption {
      type = types.str;
      description = "Name of the world.";
      default = "Dedicated";
    };

    public = mkOption {
      type = types.bool;
      description = "Whether to make the world public";
      default = false;
    };

    modifiers = mkOption {
      type = types.submodule {
        options.combat = mkOption {
          type = types.enum [
            ""
            "veryeasy"
            "easy"
            "hard"
            "veryhard"
          ];
          default = "";
        };
        options.deathpenalty = mkOption {
          type = types.enum [
            ""
            "casual"
            "veryeasy"
            "easy"
            "hard"
            "hardcore"
          ];
          default = "";
        };
        options.resources = mkOption {
          type = types.enum [
            ""
            "muchless"
            "less"
            "more"
            "muchmore"
          ];
          default = "";
        };
        options.raids = mkOption {
          type = types.enum [
            ""
            "none"
            "muchless"
            "less"
            "more"
            "muchmore"
          ];
          default = "";
        };
        options.portals = mkOption {
          type = types.enum [
            ""
            "casual"
            "hard"
            "veryhard"
          ];
          default = "";
        };
      };
      default = { };
      description = ''
        Modifiers to use, see
        <help xlink:href="https://help.akliz.net/docs/world-modifiers-for-valheim"/>
        and the
        <wiki xlink:href="https://valheim.fandom.com/wiki/World_Modifiers"/> for
        supported values.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    users.users.valheim = {
      isSystemUser = true;
      # Valheim puts save data in the home directory.
      home = cfg.dataDir;
      createHome = true;
      homeMode = "750";
      group = "valheim";
    };

    users.groups.valheim = { };

    networking.firewall = lib.mkIf cfg.openFirewall {
      allowedTCPPorts = [ cfg.port ];
      allowedUDPPorts = [ cfg.port ];
    };

    systemd.services.valheim = {
      # Install the game before launching.
      wants = [ "steam@${steam-app}.service" ];
      after = [ "steam@${steam-app}.service" ];

      serviceConfig = {
        ExecStart =
          (lib.escapeShellArgs (
            [
              "/var/lib/steam-app-${steam-app}/valheim_server.x86_64"
              "-nographics"
              "-batchmode"
              "-savedir"
              "${cfg.dataDir}/save"
              "-name"
              cfg.serverName
              "-port"
              "${toString cfg.port}"
              "-world"
              cfg.worldName
              "-public"
              (if cfg.public then "1" else "0")
            ]
            ++ (lib.lists.flatten (
              lib.mapAttrsToList (
                n: v:
                if v != "" then
                  [
                    "-modifier"
                    n
                    v
                  ]
                else
                  [ ]
              ) cfg.modifiers
            ))
          ))
          + " -password $PASSWORD";
        Nice = "-5";
        PrivateTmp = true;
        Restart = "always";
        User = "valheim";
        WorkingDirectory = "~";
        EnvironmentFile = cfg.passwordFile;
      };
      unitConfig = {
        StartLimitBurst = 2;
        StartLimitIntervalSec = 120;
      };
      environment = {
        # linux64 directory is required by Valheim.
        LD_LIBRARY_PATH = "/var/lib/steam-app-${steam-app}/linux64:${pkgs.libz}/lib:${pkgs.glibc}/lib";
        SteamAppId = "892970";
      };
    };
  };
}
