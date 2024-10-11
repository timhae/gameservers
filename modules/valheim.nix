{
  config,
  pkgs,
  lib,
  ...
}:
let
  # Set to {id}-{branch}-{password} for betas.
  steam-app = "896660";
in
{
  imports = [ ./steam.nix ];

  users.users.valheim = {
    isSystemUser = true;
    # Valheim puts save data in the home directory.
    home = "/var/lib/valheim";
    createHome = true;
    homeMode = "750";
    group = "valheim";
  };

  users.groups.valheim = { };

  systemd.services.valheim = {
    # Install the game before launching.
    wants = [ "steam@${steam-app}.service" ];
    after = [ "steam@${steam-app}.service" ];

    serviceConfig = {
      ExecStart = lib.escapeShellArgs [
        "/var/lib/steam-app-${steam-app}/valheim_server.x86_64"
        "-nographics"
        "-batchmode"
        "-savedir"
        "/var/lib/valheim/save"
        "-name"
        "derservername"
        "-port"
        "2456"
        "-world"
        "Dedicated"
        "-password"
        "todo"
        "-public"
        "0"
        "-modifier"
        "deathpenalty"
        "casual"
        "-modifier"
        "portals"
        "casual"
      ];
      Nice = "-5";
      PrivateTmp = true;
      Restart = "always";
      User = "valheim";
      WorkingDirectory = "~";
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
}
