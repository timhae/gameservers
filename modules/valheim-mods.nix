{
  config,
  lib,
  pkgs,
  inputs,
  outputs,
  ...
}:
let
  cfg = config.services.valheim-mods;
  format = pkgs.formats.toml { };
in
{
  options.services.valheim-mods = {
    enable = lib.mkEnableOption "enable valheim mods, set startup command to `./start_game_bepinex.sh; echo %command%`"; # see https://www.reddit.com/r/SteamDeck/comments/zgoazi/valheim_mods_on_the_deck/
    installDir = lib.mkOption {
      type = lib.types.str;
      default = null;
      description = "valheim installation base dir, mods will be copied here";
      example = "/home/tim/.local/share/Steam/steamapps/common/Valheim";
    };
    mods = lib.mkOption {
      type = lib.types.listOf lib.types.attrs;
      default = [ ];
      description = "mods to install, obtain hash with `nix-prefetch-url <url>` and paste like so `sha256:<hash>`";
      example = [
        rec {
          pname = "MassFarming";
          version = "1.9.0";
          src = pkgs.fetchurl {
            url = "https://thunderstore.io/package/download/k942/${pname}/${version}/";
            hash = "sha256:05cha1flc6kyky49spcrd6xwgmfr11cn7w7vws9df56m085nghvz";
          };
        }
        rec {
          pname = "MultiCraft";
          version = "1.3.0";
          src = pkgs.fetchurl {
            url = "https://thunderstore.io/package/download/MaxiMods/${pname}/${version}/";
            hash = "sha256:0fnw0d5vipqh42dg6d5r7z6mxxsf1mxcv6xvilihpn4nqnmxpy2f";
          };
          config = {
            MultiCraft.CapMaximumCrafts = true;
          };
        }
      ];
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.user.services.install-valheim-mods = {
      Unit.Description = "Copy all mods into the valheim mod directory";
      Install.WantedBy = [ "default.target" ];
      Service = {
        Type = "oneshot";
        Restart = "no";
        ExecStart =
          let
            mkMod =
              {
                pname,
                version,
                src,
                config ? { },
              }:
              {
                stdenv,
                unzip,
                ilspycmd,
                ripgrep,
                fd,
              }:
              stdenv.mkDerivation rec {
                inherit pname version src;
                dontPatch = true;
                dontConfigure = true;
                dontBuild = true;
                dontInstall = true;
                dontFixup = true;
                unpackPhase = ''
                  mkdir -p $out
                  ${unzip}/bin/unzip -jq $src || true # ignore backslash warning
                  dllName="$(${fd}/bin/fd -t f '\.dll$')"
                  configName="$(${ilspycmd}/bin/ilspycmd $dllName | ${ripgrep}/bin/rg '.*\[BepInPlugin\("([^"]+)".*' -r '$1' ).cfg"
                  cat ${format.generate "${pname}-config" config} > "$out/$configName"
                  mv -v $dllName $out/
                '';
              };
            modDerivations = map (mod: pkgs.callPackage (mkMod mod) { }) cfg.mods;
            bepInEx = pkgs.callPackage (
              {
                stdenv,
                unzip,
                fd,
              }:
              stdenv.mkDerivation rec {
                pname = "BepInExPack_Valheim";
                version = "5.4.2202";
                src = pkgs.fetchurl {
                  url = "https://thunderstore.io/package/download/denikson/${pname}/${version}/";
                  sha256 = "sha256-2cOxaZKqagIGmpIaPk1hMkD+KRKCu2f+kiYbAMb6v4w=";
                };
                dontPatch = true;
                dontConfigure = true;
                dontBuild = true;
                dontInstall = true;
                dontFixup = true;
                # TODO: remove no longer active mods
                unpackPhase = ''
                  mkdir -p $out
                  ${unzip}/bin/unzip $src
                  mv -v ${pname}/* $out/
                  for modDerivationPath in ${toString (map (modDrv: modDrv.outPath) modDerivations)}; do
                    cd $modDerivationPath
                    dllName="$(${fd}/bin/fd -t f 'dll')"
                    ln -sfv $PWD/$dllName $out/BepInEx/plugins/$dllName
                    configName="$(${fd}/bin/fd -t f 'cfg')"
                    cp -fv $PWD/$configName $out/BepInEx/config/$configName
                    chmod 777 $out/BepInEx/config/$configName
                  done
                '';
              }
            ) { };
          in
          "${pkgs.writers.writeBashBin "install-valheim-mods" ''
            ${pkgs.rsync}/bin/rsync -av ${bepInEx.outPath}/* ${cfg.installDir}
            ${pkgs.coreutils}/bin/chmod -R 777 ${cfg.installDir}/BepInEx/
            ${pkgs.coreutils}/bin/chmod +x ${cfg.installDir}/start_game_bepinex.sh
          ''}/bin/install-valheim-mods";
      };
    };
  };
}
