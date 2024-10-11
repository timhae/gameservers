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
  imports = [
    ./steam.nix
  ];

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
    wantedBy = [ "multi-user.target" ];

    # Install the game before launching.
    wants = [ "steam@${steam-app}.service" ];
    after = [ "steam@${steam-app}.service" ];

    serviceConfig = {
      ExecStartPre =
        let
          install-mods = pkgs.writeShellApplication {
            name = "install-mods";
            runtimeInputs = with pkgs; [
              curl
              unzip
              coreutils
              rsync
            ];
            text = ''
              mkdir -p ~/mods
              cd ~/mods || exit 1

              # Bepinex
              curl -JL0 https://valheim.thunderstore.io/package/download/denikson/BepInExPack_Valheim/5.4.2202/ -o ./BepInExPack_Valheim.zip
              unzip -o ./BepInExPack_Valheim.zip

              # Mods
              curl -JL0 https://valheim.thunderstore.io/package/download/MaxiMods/MultiCraft/1.3.0/ -o ./MultiCraft.zip
              unzip -o ./MultiCraft.zip -d ./BepInExPack_Valheim/BepInEx/plugins
              curl -JL0 https://valheim.thunderstore.io/package/download/k942/MassFarming/1.9.0/ -o ./MassFarming.zip
              unzip -o ./MassFarming.zip -d ./BepInExPack_Valheim/BepInEx/plugins
              curl -JL0 https://valheim.thunderstore.io/package/download/LVH-IT/UseEquipmentInWater/0.2.4/ -o ./UseEquipmentInWater.zip
              unzip -o ./UseEquipmentInWater.zip -d ./BepInExPack_Valheim/BepInEx/plugins

              # Install
              rsync -a ./BepInExPack_Valheim/* /var/lib/steam-app-${steam-app}
            '';
          };
        in
        "${install-mods}/bin/install-mods";
      ExecStart = lib.escapeShellArgs [
        "/var/lib/steam-app-${steam-app}/valheim_server.x86_64"
        "-nographics"
        "-batchmode"
        # "-crossplay" # This is broken because it looks for "party" shared library in the wrong path.
        "-savedir"
        "/var/lib/valheim/save"
        "-name"
        "derservername"
        "-port"
        "2456"
        "-world"
        "Dedicated"
        "-password"
        "supersecret"
        "-public"
        "0" # Valheim now supports favourite servers in-game which I am using instead of listing in the public registry.
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
      LD_LIBRARY_PATH = "/var/lib/steam-app-${steam-app}/linux64:/var/lib/steam-app-${steam-app}/doorstop_libs:${pkgs.libz}/lib:${pkgs.glibc}/lib";
      DOORSTOP_ENABLE = "TRUE";
      DOORSTOP_INVOKE_DLL_PATH = "/var/lib/steam-app-${steam-app}/BepInEx/core/BepInEx.Preloader.dll";
      LD_PRELOAD = "libdoorstop_x64.so:$LD_PRELOAD";
      SteamAppId = "892970";
    };
  };
}
