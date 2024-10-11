{
  stdenv,
  lib,
  mono,
  file,
  fetchurl,
  makeWrapper,
  autoPatchelfHook,
  unzip,
  tModLoader ? true,
}:

stdenv.mkDerivation rec {
  pname = "terraria-server";
  version = "1.4.4.9";
  urlVersion = lib.replaceStrings [ "." ] [ "" ] version;

  src = fetchurl {
    url = "https://terraria.org/api/download/pc-dedicated-server/terraria-server-${urlVersion}.zip";
    sha256 = "sha256-Mk+5s9OlkyTLXZYVT0+8Qcjy2Sb5uy2hcC8CML0biNY=";
  };

  tmod-version = "v2022.09.47.44";
  src-tmod = fetchurl {
    url = "https://github.com/tModLoader/tModLoader/releases/download/${tmod-version}/tModLoader.zip";
    sha256 = "sha256-ZAFREckNHVG7vXzesNHMq5cLzyPyPhjjRYnRKo/KvDw=";
  };

  buildInputs = [ file ];
  nativeBuildInputs = [
    makeWrapper
    autoPatchelfHook
    unzip
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    cp -r Linux $out/
    rm $out/Linux/System*
    rm $out/Linux/Mono*
    rm $out/Linux/monoconfig
    rm $out/Linux/mscorlib.dll
    chmod +x "$out/Linux/TerrariaServer.exe"
    # TMOD
    ${lib.optionalString tModLoader ''
            ${unzip}/bin/unzip tModLoader.zip -d $out/

              library_dir="$root_dir/Libraries/Native/Linux"
              export LD_LIBRARY_PATH="$library_dir"
              ln -sf "$library_dir/libSDL2-2.0.so.0" "$library_dir/libSDL2.so"

      install dotnet
    ''}
    makeWrapper ${mono}/bin/mono $out/bin/terraria-server \
      --add-flags "--server --gc=sgen -O=all '$out/Linux/TerrariaServer.exe'"

    runHook postInstall
  '';

  meta = with lib; {
    homepage = "https://terraria.org";
    description = "Dedicated server for Terraria, a 2D action-adventure sandbox";
    # platforms = [ "x86_64-linux" ]; # TODO: https://www.reddit.com/r/Terraria/comments/gl5fl8/guide_how_to_setup_a_terraria_14_server_on_a/
  };
}
