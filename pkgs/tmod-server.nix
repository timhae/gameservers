{ stdenv
, lib
, file
, fetchurl
, autoPatchelfHook
, unzip
}:

stdenv.mkDerivation rec {
  pname = "tmod-server";
  version = "1.4.4.9";
  urlVersion = lib.replaceStrings [ "." ] [ "" ] version;

  src = fetchurl {
    url = "https://terraria.org/api/download/pc-dedicated-server/terraria-server-${urlVersion}.zip";
    sha256 = "sha256-Mk+5s9OlkyTLXZYVT0+8Qcjy2Sb5uy2hcC8CML0biNY=";
  };

  tmod-src = fetchurl {
    url = "";
    sha256 = lib.fakeSha256;
  };

  buildInputs = [ file ];
  nativeBuildInputs = [ autoPatchelfHook unzip ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    cp -r Linux $out/
    chmod +x "$out/Linux/TerrariaServer.bin.x86_64"
    ln -s "$out/Linux/TerrariaServer.bin.x86_64" $out/bin/TerrariaServer

    runHook postInstall
  '';

  meta = with lib; {
    homepage = "https://terraria.org";
    description = "Dedicated server for Terraria, a 2D action-adventure sandbox";
    # platforms = [ "x86_64-linux" ]; # TODO: https://www.reddit.com/r/Terraria/comments/gl5fl8/guide_how_to_setup_a_terraria_14_server_on_a/
  };
}
