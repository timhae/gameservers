{ alsa-lib
, autoPatchelfHook
, callPackage
, fetchurl
, fetchzip
, fontconfig
, gnused
, icu
, jq
, lib
, libGL
, libkrb5
, lttng-ust_2_12
, makeWrapper
, openssl_1_1
, requireFile # TODO: would be nicer than hosting the gamefiles on my server
, stdenv
, unzip
, xorg
, zlib
, stateDir ? "/var/lib/stardew-server"
, saveName ? "Tim_239568989"
  # configure SMAPI options, see src/SMAPI/SMAPI.config.json in the SMAPI repo
  # for possible values
, smapiConfig ? {
    ConsoleColors = {
      UseScheme = "DarkBackground";
    };
  }
  # override needs to copy entire mod list but that at least allows for some
  # kind of customization vs a let binding
, modList ? [
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
  ]
}:
let
  mkMod =
    { pname
    , version
    , src
    , url
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
        modpath=$out/${pname}
        mkdir -p $modpath
        # each zip file should contain all mod files in the root directory and
        # not inside another directory with the name of the mod. some mod names
        # contain spaces and I don't want to deal with that.
        ${unzip}/bin/unzip $src -d $modpath
        # read config.json and merge with provided config overwriting values
        # creating the file if it doesn't exist
        [[ -f $modpath/config.json ]] && confOld=$(< $modpath/config.json) || confOld="{}"
        confNew='${builtins.toJSON modConfig}'
        ${jq}/bin/jq -s '.[0] * .[1]' <<< "$confOld $confNew" > $modpath/config.json
        runHook postUnpack
      '';
    };
  modDrvs = map (mod: callPackage (mkMod mod) { }) modList;
  modDrvsPaths = map (modDrv: modDrv.outPath + "/" + modDrv.pname) modDrvs;
  setupScript = ''
    # GAMEFILES
    if [[ ! -e "${stateDir}" ]]; then
      echo "please make sure that '${stateDir}' exists before you run this program"
      exit 1
    fi
    cp -nr --no-preserve=all -t "${stateDir}/" "$store_path/."
    # MODS
    for modDrvPath in ${toString modDrvsPaths}; do
      cp -nr --no-preserve=all -t "${stateDir}/Mods/" $modDrvPath
    done
    # SMAPI CONF
    confOld=$(${gnused}/bin/sed -e '1,16d' -e '/.*\*.*/d' < "$store_path/smapi-internal/config.json")
    confNew='${builtins.toJSON smapiConfig}'
    ${jq}/bin/jq -s '.[0] * .[1]' <<< "$confOld $confNew" > "${stateDir}/smapi-internal/config.json"
    chmod +x "${stateDir}/StardewValley"
  '';
in
stdenv.mkDerivation rec {
  pname = "stardew-server";
  # get version from here https://steamdb.info/app/413150/depots/?branch=public
  # or from steam (right click Stardew Valley, properties -> updates)
  version = "8043676";
  src = fetchurl {
    url = "https://haering.dev/stardew-valley-mods/${pname}-${version}.zip";
    sha256 = "sha256-5e7NesAH+F6eTjiyI4Zd+aiaLr14CEVTeJLs4Dzjz+g=";
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
    mkdir -p $out/bin
    ${unzip}/bin/unzip ${src} -d $out
    ${unzip}/bin/unzip -o ${src-smapi}/internal/linux/install.dat -d $out
    runHook postUnpack
  '';
  installPhase = ''
    runHook preInstall
    # SMAPI
    cp $out/Stardew\ Valley.deps.json $out/StardewModdingAPI.deps.json
    mv $out/StardewValley $out/StardewValley-original
    mv $out/StardewModdingAPI $out/StardewValley
    # EXE
    makeWrapper $out/StardewValley $out/bin/stardew-server \
      --set store_path $out \
      --run ${lib.escapeShellArg setupScript} \
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath [
        alsa-lib
        icu
        libGL
        openssl_1_1
        xorg.libXi
      ]}"
    ${gnused}/bin/sed -i "s:\"$out/StardewValley\":'${stateDir}/StardewValley':" $out/bin/stardew-server
    runHook postInstall
  '';
}
