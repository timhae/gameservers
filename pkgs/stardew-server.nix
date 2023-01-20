with import <nixpkgs> {};
{ lib
, stdenvNoCC
, steam-run
, makeWrapper
, runtimeShell
, requireFile
, unzip
}:
stdenvNoCC.mkDerivation rec {
  pname = "stardew-server";

  version = "0.0.1";

  src = requireFile rec {
    name = "stardew-server-${version}.zip";
    message = ''
      This nix expression requires that ${name} is already part of the store.
      Zip the folder in "~/.local/share/Steam/steamapps/common" with
      "zip -r stardew-server-${version}.zip Stardew\ Valley/*", and add it to
      the nix store with "nix-prefetch-url file://\$PWD/${name}".
    '';
    sha256 = "0sakpfwhh2z7zz6ny32dpdsqdwhx8rrinfs2wphn98jzajsgvvl2";
  };

  buildInputs = [ steam-run ];

  nativeBuildInputs = [ makeWrapper ];

  unpackPhase = ''
    ${unzip}/bin/unzip ${src}
  '';

  installPhase = ''
    mkdir -p $out/bin $out/files
    cp -r Stardew\ Valley/* "$out/files"
    cat > $out/bin/stardew-server <<EOF
    #!${runtimeShell}
    export PATH=${steamcmd}/bin:\$PATH
    exec ${steam-run}/bin/steam-run $out/files/Stardew\ Valley '\$@'
    EOF
    chmod +x $out/bin/stardew-server
  '';
}
