{ alsa-lib
, autoPatchelfHook
, callPackage
, fetchurl
, fetchzip
, fontconfig
, icu
, lib
, libGL
, libkrb5
, lttng-ust_2_12
, makeWrapper
, openssl_1_1
, requireFile
, stdenv
, unzip
, xorg
, zlib
  # either pass to the stardew-server wrapper or override here or use default
  # value
, modPath ? "/var/lib/stardew-server/"
  # override needs to copy entire mod list but that at least allows for some
  # kind of customization vs a let binding
, modList ? [
    rec {
      pname = "AutoLoadGame";
      version = "1.0.2";
      src = fetchurl {
        url = "https://haering.dev/stardew-valley-mods/${pname}-${version}.zip";
        sha256 = "sha256-IaH+feaREwkHIm6GKfmrmmgzXzPMSQjMUSRwCj2Ll+o=";
      };
      modConfig = {
        LastFileLoaded = "Tim_239568989"; # The save name that will be loaded. (This is automatically set whenever you load or save a game. You don't need to set this yourself)
        LoadIntoMultiplayer = true; # Load the save as a multiplayer session. (Default False)
        ForgetLastFileOnTitle = false; # Only reload the save if the game was quit from ingame, not from the title (Default True)
      };
    }
    # works when started through the serverHotKey but fails when calling server
    # on the SMAPI console, I don't think I need that actually.. it just
    # continues to play on its own, I just want to have a server to which I can
    # connect when I start it
    rec {
      pname = "AlwaysOnServer";
      version = "1.20.2";
      src = fetchurl {
        url = "https://haering.dev/stardew-valley-mods/${pname}-${version}.zip";
        sha256 = "sha256-a8QzyyjntFGJ2OWrGA7pAcX0mId7nEDu6v62sGw30Ww=";
      };
    }
    rec {
      pname = "ChatCommands";
      version = "1.15.2";
      src = fetchurl {
        url = "https://haering.dev/stardew-valley-mods/${pname}-${version}.zip";
        sha256 = "sha256-HDUMy1XYxFXSE6WQ+uk8ALl3iW9VrGHBxZUZ3ZqW4Gg=";
      };
    }
    rec {
      pname = "NoFenceDecay";
      version = "1.5.0";
      src = fetchurl {
        url = "https://haering.dev/stardew-valley-mods/${pname}-${version}.zip";
        sha256 = "sha256-xG4kykQZnM1mOD3tvrCfT53MQVfZ/DZWFGs9jmwjW9I=";
      };
    }
    rec {
      pname = "RemoteControl";
      version = "1.0.1";
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
      src = fetchurl {
        url = "https://haering.dev/stardew-valley-mods/${pname}-${version}.zip";
        sha256 = "sha256-ct36mK6mZWFtgMgUP5bnsD/3ySu+aVnI68r4wDnSjyU=";
      };
    }
    rec {
      pname = "UnlimitedPlayers";
      version = "2021.2.27";
      src = fetchurl {
        url = "https://haering.dev/stardew-valley-mods/${pname}-${version}.zip";
        sha256 = "sha256-hz2vDXacCkXsXyl1RmsN4avSN/yZm2YOPUTP5pHl7sc=";
      };
    }
  ]
}:
let
  mkMod =
    { pname
    , version
    , src
    , modConfig ? { }
    }:
    { stdenv
    , fetchurl
    , unzip
    , jq
    , lib
    , writeText
    }: stdenv.mkDerivation rec {
      inherit pname version src;
      dontPatch = true;
      dontConfigure = true;
      dontBuild = true;
      dontInstall = true;
      dontFixup = true;
      unpackPhase = ''
        runHook preUnpack
        modpath="$out/${pname}"
        mkdir -p "$modpath"
        # each zip file should contain all mod files in the root directory and
        # not inside another directory with the name of the mod. some mod names
        # contain spaces and I don't want to deal with that
        ${unzip}/bin/unzip $src -d "$modpath"
        # read config.json and merge with provided config overwriting values
        # creating the file if it doesn't exist
        [[ -f "$modpath/config.json" ]] && confOld=$(< "$modpath/config.json") || confOld="{}"
        confNew='${builtins.toJSON modConfig}'
        ${jq}/bin/jq -s '.[0] * .[1]' <<< "$confOld $confNew" > "$modpath/config.json"
        runHook postUnpack
      '';
    };
  modDrvs = map (mod: callPackage (mkMod mod) { }) modList;
  modDrvsPaths = map (modDrv: modDrv.outPath + "/" + modDrv.pname) modDrvs;
  copyMods = ''
    copyMods() {
      mkdir -p "$1"
      cp -rf "$mods_src_dir" "$1"
      chmod +w -R "$1"
      export SMAPI_MODS_PATH="$1"
    }
    if [[ $# -eq 0 ]]; then
      copyMods "${modPath}"
    else
      copyMods "$1"
    fi
  '';
in
stdenv.mkDerivation rec {
  pname = "stardew-server";
  version = "20220118";
  src = requireFile rec {
    # TODO: same folder content has different hashes due to timestamps probably, write instructions reflecting that
    name = "stardew-server-${version}.zip";
    message = ''
      This nix expression requires that ${name} is already part of the store.
      Zip the game folder in "~/.local/share/Steam/steamapps/common" with
      "zip -r ${name} Stardew\ Valley/*", and add it to the nix store with
      "nix-prefetch-url file://\$PWD/${name}".
      Make sure that your game version is the same as the one listed here
      https://steamdb.info/depot/413153/manifests/ with date ${version}.
    '';
    sha256 = "17s6a6xrbgcw34f4rmf5qhlrm7wpqd8jhyik5gdanwr0vs1sxci1";
  };
  smapi-version = "3.18.2";
  src-smapi = fetchzip {
    url = "https://github.com/Pathoschild/SMAPI/releases/download/${smapi-version}/SMAPI-${smapi-version}-installer.zip";
    sha256 = "sha256-dBNO5DtypwsSqMWVr8imSqBt61BMKFZhOQ9xuso77zo=";
  };
  dontPatch = true;
  dontConfigure = true;
  dontBuild = true;
  nativeBuildInputs = [ autoPatchelfHook makeWrapper ];
  buildInputs = [
    fontconfig
    libkrb5
    lttng-ust_2_12
    stdenv.cc.cc
    zlib
  ];
  unpackPhase = ''
    runHook preUnpack
    mkdir -p $out/bin $out/files
    ${unzip}/bin/unzip ${src}
    mv Stardew\ Valley/* $out/files
    rm -rf Stardew\ Valley/
    ${unzip}/bin/unzip -o ${src-smapi}/internal/linux/install.dat -d $out/files
    runHook postUnpack
  '';
  installPhase = ''
    runHook preInstall
    # SMAPI
    cp $out/files/Stardew\ Valley.deps.json $out/files/StardewModdingAPI.deps.json
    mv $out/files/StardewValley $out/files/StardewValley-original
    mv $out/files/StardewModdingAPI $out/files/StardewValley
    # MODS
    for modDrv in ${toString modDrvsPaths}; do
      cp -vr "$modDrv" "$out/files/Mods/"
    done
    # EXE
    makeWrapper $out/files/StardewValley $out/bin/stardew-server \
      --set mods_src_dir "$out/files/Mods/" \
      --run ${lib.escapeShellArg copyMods} \
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath [
        alsa-lib
        icu
        libGL
        openssl_1_1
        xorg.libXi
      ]}"
    runHook postInstall
  '';
}
