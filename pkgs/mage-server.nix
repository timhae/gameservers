{ stdenv
, fetchzip
, jdk11
, maven
, protobuf
, inShell ? false
}:
stdenv.mkDerivation rec {
  version = "20231231";
  src =
    if inShell then
      null
    else
      fetchzip {
        stripRoot = false;
        url = "http://haering.dev/xmage/mage-server-${version}.zip";
        sha256 = "sha256-st1iNrYmHsxvnYw5O/+VjLoJv/JcErih0ydQJTHWwJI=";
      };
  pname = "mage-server";
  buildInputs = if inShell then [ jdk11 maven protobuf ] else [ ];
  installPhase = ''
    mkdir -p $out/bin $out/extension $out/plugins
    cp -rv ./* $out

    cat << EOF > $out/bin/mage-server
    #!/usr/bin/env bash
    exec ${pkgs.jdk11}/bin/java -Xms1g -Xmx4g \
      -Dfile.encoding=UTF-8 \
      -Djava.security.policy=$out/config/security.policy \
      -Dlog4j.configuration=file:$out/config/log4j.properties \
      -Dconfig-path=$out/config/config.xml \
      -Dplugin-path=$out/plugins/ \
      -Dextension-path=$out/extension/ \
      -Dmessage-path=$out/ \
      -jar $out/lib/${pname}-1.4.50.jar
    EOF

    chmod +x $out/bin/mage-server
  '';
}
