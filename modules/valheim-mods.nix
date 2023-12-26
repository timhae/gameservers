{ config, lib, pkgs, inputs, outputs, ... }:
let
  cfg = config.services.valheim-mods;
in
{
  options.services.valheim-mods = {
    enable = lib.mkEnableOption "enable valheim mods";
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
          uploader = "k942";
          version = "1.9.0";
          src = pkgs.fetchurl {
            url = "https://valheim.thunderstore.io/package/download/${uploader}/${pname}/${version}/";
            hash = "sha256:05cha1flc6kyky49spcrd6xwgmfr11cn7w7vws9df56m085nghvz";
          };
        }
        rec {
          pname = "MultiCraft";
          uploader = "MaxiMods";
          version = "1.3.0";
          src = pkgs.fetchurl {
            url = "https://valheim.thunderstore.io/package/download/${uploader}/${pname}/${version}/";
            hash = "sha256:0fnw0d5vipqh42dg6d5r7z6mxxsf1mxcv6xvilihpn4nqnmxpy2f";
          };
        }
        rec {
          pname = "UseEquipmentInWater";
          uploader = "LVH-IT";
          version = "0.2.4";
          src = pkgs.fetchurl {
            url = "https://valheim.thunderstore.io/package/download/${uploader}/${pname}/${version}/";
            hash = "sha256:0hhb7mf3gh3mi46p5dgr48fykgq8a8k6czqad5hb0yyv4glr51r2";
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
              { pname, uploader, version, src }:
              { stdenv, unzip }: stdenv.mkDerivation rec {
                inherit pname version src;
                dontPatch = true;
                dontConfigure = true;
                dontBuild = true;
                dontInstall = true;
                dontFixup = true;
                unpackPhase = ''
                  mkdir -p $out
                  ${unzip}/bin/unzip $src
                  mv -v ${pname}.dll $out/
                '';
              };
            modDerivations = map (mod: pkgs.callPackage (mkMod mod) { }) cfg.mods;
            modDerivationsDllPath = map (modDrv: modDrv.outPath + "/" + modDrv.pname + ".dll") modDerivations;
            bepInEx = pkgs.callPackage
              ({ stdenv, unzip }: stdenv.mkDerivation rec {
                pname = "BepInExPack_Valheim";
                version = "5.4.2202";
                src = pkgs.fetchurl {
                  url = "https://valheim.thunderstore.io/package/download/denikson/${pname}/${version}/";
                  sha256 = "sha256-2cOxaZKqagIGmpIaPk1hMkD+KRKCu2f+kiYbAMb6v4w=";
                };
                dontPatch = true;
                dontConfigure = true;
                dontBuild = true;
                dontInstall = true;
                dontFixup = true;
                unpackPhase = ''
                  mkdir -p $out
                  ${unzip}/bin/unzip $src
                  mv -v ${pname}/* $out/
                  cd $out/BepInEx/plugins
                  for modDerivationDllPath in ${toString modDerivationsDllPath}; do
                    ln -sfv $modDerivationDllPath
                  done
                '';
              })
              { };
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
