{
  stdenv,
  fetchurl,
  unzip,
  jq,
  modConfig ? {
    serverHotKey = "F10";
    profitmargin = 99;
    clientsCanPause = true;
  },
}:
stdenv.mkDerivation rec {
  pname = "RemoteControl";
  version = "1.0.1";
  src = fetchurl {
    url = "https://haering.dev/stardew-valley-mods/${pname}-${version}.zip";
    sha256 = "sha256-1J6RDFloaF5OluBQSWsTpnvGNQITYekfJac8EXkrzGo=";
  };
  dontPatch = true;
  dontConfigure = true;
  dontBuild = true;
  dontInstall = true;
  dontFixup = true;
  unpackPhase = ''
    runHook preUnpack
    modpath="$out/${pname}"
    mkdir -p "$modpath"
    ${unzip}/bin/unzip $src -d "$modpath"
    # read config.json and merge with provided config overwriting values
    # creating the file if it doesn't exist
    [[ -f "$modpath/config.json" ]] && confOld=$(< "$modpath/config.json") || confOld="{}"
    confNew='${builtins.toJSON modConfig}'
    ${jq}/bin/jq -s '.[0] * .[1]' <<< "$confOld $confNew" > "$modpath/config.json"
    runHook postUnpack
  '';
}
