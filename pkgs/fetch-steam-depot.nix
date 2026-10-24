{
  cacert,
  depotdownloader,
  lib,
  stdenvNoCC,
}:
let
  # Avoid the double-poll bug that makes a reconnect during Steam Guard entry
  # fail with EResult.FileNotFound, see depotdownloader-auth-race.patch.
  depotdownloader' = depotdownloader.overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [ ./depotdownloader-auth-race.patch ];
  });
in
{
  pname,
  appId,
  depotId,
  manifestId,
  branch ? "public",
  version ? toString manifestId,
  hash,
}:
stdenvNoCC.mkDerivation {
  name = "${pname}-${version}";

  nativeBuildInputs = [
    cacert
    depotdownloader'
  ];

  # Credentials are intentionally not part of the derivation. They are read
  # from the environment of the build process (the nix-daemon when using a
  # multi-user installation) and never end up in the Nix store.
  impureEnvVars = [
    "STEAM_USERNAME"
    "STEAM_PASSWORD"
    "STEAM_GUARD_CODE"
  ]
  ++ lib.fetchers.proxyImpureEnvVars;

  outputHash = hash;
  outputHashAlgo = "sha256";
  outputHashMode = "recursive";

  dontUnpack = true;
  dontConfigure = true;
  dontBuild = true;
  dontInstall = true;
  dontFixup = true;

  buildCommand = ''
    set -eu -o pipefail

    export HOME="$TMPDIR/home"
    export XDG_DATA_HOME="$HOME/.local/share"
    export XDG_CONFIG_HOME="$HOME/.config"
    mkdir -p "$HOME" "$XDG_DATA_HOME" "$XDG_CONFIG_HOME"

    export SSL_CERT_FILE="${cacert}/etc/ssl/certs/ca-bundle.crt"
    export NIX_SSL_CERT_FILE="$SSL_CERT_FILE"
    export SSL_CERT_DIR="${cacert}/etc/ssl/certs"

    if [ -z "''${STEAM_USERNAME:-}" ] || [ -z "''${STEAM_PASSWORD:-}" ]; then
      echo "error: STEAM_USERNAME and STEAM_PASSWORD must be set to download Steam depot ${toString depotId} from app ${toString appId}." >&2
      echo "       The account must own the app. For Steam Guard, also set STEAM_GUARD_CODE." >&2
      echo "       With a multi-user Nix daemon these variables have to be in the daemon's environment." >&2
      echo "       Alternatively, prefetch the depot with the package's prefetch-* app." >&2
      exit 1
    fi

    {
      printf '%s\n' "$STEAM_PASSWORD"
      if [ -n "''${STEAM_GUARD_CODE:-}" ]; then
        printf '%s\n' "$STEAM_GUARD_CODE"
      fi
    } | ${depotdownloader'}/bin/DepotDownloader \
      -app ${toString appId} \
      -depot ${toString depotId} \
      -manifest ${toString manifestId} \
      -branch ${lib.escapeShellArg branch} \
      -username "$STEAM_USERNAME" \
      -no-mobile \
      -dir "$out"

    # This is DepotDownloader's bookkeeping, not game content.
    rm -rf "$out/.DepotDownloader"
  '';
}
