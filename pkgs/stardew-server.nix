{ alsa-lib
, autoPatchelfHook
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
}:
stdenv.mkDerivation rec {
  pname = "stardew-server";
  version = "20220118";
  smapi-version = "3.18.1";
  src = requireFile rec {
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
  src-smapi = fetchzip {
    url = "https://github.com/Pathoschild/SMAPI/releases/download/${smapi-version}/SMAPI-${smapi-version}-installer.zip";
    sha256 = "sha256-kuPCDKXdD5HL7+7OQgqxSM35At2o901CVGnhaxYLqZ0=";
  };
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
    mkdir -p unzip
    ${unzip}/bin/unzip ${src}
    mv Stardew\ Valley/* unzip/
    rm -rf Stardew\ Valley/
    ${unzip}/bin/unzip -o ${src-smapi}/internal/linux/install.dat -d unzip
    runHook postUnpack
  '';
  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin $out/files
    cp -r unzip/* $out/files
    cp $out/files/Stardew\ Valley.deps.json $out/files/StardewModdingAPI.deps.json
    mv $out/files/StardewValley $out/files/StardewValley-original
    mv $out/files/StardewModdingAPI $out/files/StardewValley
    makeWrapper $out/files/StardewValley $out/bin/stardew-server \
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
