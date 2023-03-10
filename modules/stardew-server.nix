{ config, lib, pkgs, ... }:
let
  cfg = config.services.stardew-server;
  varLibStateDir = "/var/lib/${cfg.stateDir}";
  format = pkgs.formats.json { };
  package = pkgs.stardew-server.override {
    stateDir = varLibStateDir;
    saveName = cfg.saveName;
    smapiConfig = cfg.smapiConfig;
    modList = cfg.modList;
  };
in
with lib; {
  options = {
    services.stardew-server = {
      enable = mkEnableOption "enable stardew-server";
      openFirewall = mkEnableOption "open ports for stardew-server";
      stateDir = mkOption {
        type = types.str;
        default = "stardew-server";
        description = ''
          Directory to store all stateful configuration, logs and save files.
          Will be created as subdirectory of <literal>/var/lib/</literal>.
        '';
      };
      saveName = mkOption {
        type = types.str;
        default = "Tim_239568989";
        description = "Save game to load.";
      };
      smapiConfig = mkOption {
        type = format.type;
        default = { };
        example = literalExpression ''
          {
            ConsoleColors = {
              UseScheme = "DarkBackground";
            };
          }'';
        description = ''
          Game settings as defined in <link xlink:href="https://github.com/Pathoschild/SMAPI/blob/develop/src/SMAPI/SMAPI.config.json">this file</link>.
          Look at the reference to see what you can configure in this attribute set.
        '';
      };
      modList = mkOption {
        type = types.list;
        default = [
          rec {
            pname = "AutoLoadGame";
            version = "1.0.2";
            url = "https://github.com/Caraxi/StardewValleyMods/tree/master/AutoLoadGame";
            src = fetchurl {
              url = "https://haering.dev/stardew-valley-mods/${pname}-${version}.zip";
              sha256 = "sha256-IaH+feaREwkHIm6GKfmrmmgzXzPMSQjMUSRwCj2Ll+o=";
            };
            modConfig = {
              LastFileLoaded = saveName;
              LoadIntoMultiplayer = true;
              ForgetLastFileOnTitle = false;
            };
          }
          # works when started through the serverHotKey but fails when calling server
          # on the SMAPI console, I don't think I need that actually.. it just
          # continues to play on its own, I just want to have a server to which I can
          # connect when I start it. But also someone needs to start that server. How
          # would I connect as the host that started the server?
          rec {
            pname = "AlwaysOnServer";
            version = "1.20.2";
            url = "https://forums.stardewvalley.net/threads/unofficial-mod-updates.2096/page-47#post-29677";
            src = fetchurl {
              url = "https://haering.dev/stardew-valley-mods/${pname}-${version}.zip";
              sha256 = "sha256-a8QzyyjntFGJ2OWrGA7pAcX0mId7nEDu6v62sGw30Ww=";
            };
          }
          rec {
            pname = "ChatCommands";
            version = "1.15.2";
            url = "https://github.com/danvolchek/StardewMods/tree/master/ChatCommands";
            src = fetchurl {
              url = "https://haering.dev/stardew-valley-mods/${pname}-${version}.zip";
              sha256 = "sha256-HDUMy1XYxFXSE6WQ+uk8ALl3iW9VrGHBxZUZ3ZqW4Gg=";
            };
          }
          rec {
            pname = "NoFenceDecay";
            version = "1.5.0";
            url = "https://github.com/danvolchek/StardewMods/tree/master/NoFenceDecay";
            src = fetchurl {
              url = "https://haering.dev/stardew-valley-mods/${pname}-${version}.zip";
              sha256 = "sha256-xG4kykQZnM1mOD3tvrCfT53MQVfZ/DZWFGs9jmwjW9I=";
            };
          }
          rec {
            pname = "RemoteControl";
            version = "1.0.1";
            url = "https://github.com/atravita-mods/stardew-remote-control";
            src = fetchurl {
              url = "https://haering.dev/stardew-valley-mods/${pname}-${version}.zip";
              sha256 = "sha256-1J6RDFloaF5OluBQSWsTpnvGNQITYekfJac8EXkrzGo=";
            };
            modConfig = {
              everyoneIsAdmin = true;
            };
          }
          rec {
            pname = "TimeSpeed";
            version = "2.7.5";
            url = "https://github.com/cantorsdust/StardewMods/tree/master/TimeSpeed";
            src = fetchurl {
              url = "https://haering.dev/stardew-valley-mods/${pname}-${version}.zip";
              sha256 = "sha256-ct36mK6mZWFtgMgUP5bnsD/3ySu+aVnI68r4wDnSjyU=";
            };
          }
          rec {
            pname = "UnlimitedPlayers";
            version = "2021.2.27";
            url = "https://github.com/Armitxes/StardewValley_UnlimitedPlayers";
            src = fetchurl {
              url = "https://haering.dev/stardew-valley-mods/${pname}-${version}.zip";
              sha256 = "sha256-hz2vDXacCkXsXyl1RmsN4avSN/yZm2YOPUTP5pHl7sc=";
            };
          }
        ];
        example = literalExpression ''
          [
            {
              pname = "RemoteControl";
              version = "1.0.1";
              url = "https://github.com/atravita-mods/stardew-remote-control";
              src = fetchurl {
                url = "https://haering.dev/stardew-valley-mods/''${pname}-''${version}.zip";
                sha256 = "sha256-1J6RDFloaF5OluBQSWsTpnvGNQITYekfJac8EXkrzGo=";
              };
              modConfig = {
                everyoneIsAdmin = false;
              };
            }
          ]'';
        description = ''
          List of mods that will be included. Each zipfile only contains the mod
          files without a root directory of the name of the mod. Configuration
          of the mod can be adapted by providing a 'modConfig' attrset which
          will be translated to a config.json file in the folder of the mod.
        '';
      };
    };
  };
  config = mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = mkIf cfg.openFirewall [ 24642 ];
    networking.firewall.allowedUDPPorts = mkIf cfg.openFirewall [ 24642 ];
    systemd.services.vrising-server = {
      description = "Stardew Valley dedicated server";
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" ];
      serviceConfig = {
        ExecStart = ''
          exec ${pkgs.xvfb-run}/bin/xvfb-run \
            --auto-servernum \
            --server-args='-screen 0 320x180x8' \
            ${package}/bin/stardew-server
        '';
        WorkingDirectory = varLibStateDir;
        Restart = "no";
        StateDirectory = cfg.stateDir;
        DynamicUser = true;
        # Hardening
        SystemCallFilter = "@system-service @mount @debug";
        SystemCallErrorNumber = "EPERM";
        CapabilityBoundingSet = "";
        RestrictNamespaces = "cgroup mnt user uts";
        RestrictAddressFamilies = "AF_UNIX AF_INET AF_INET6 AF_NETLINK";
      };
    };
  };
}
