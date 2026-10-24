{
  coreutils,
  depotdownloader,
  lib,
  nix,
  writeShellApplication,
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
  version,
  appId,
  depotId,
  manifestId,
  branch ? "public",
}:
writeShellApplication {
  name = "prefetch-${pname}";

  runtimeInputs = [
    coreutils
    depotdownloader'
    nix
  ];

  text = ''
    if [ -z "''${STEAM_USERNAME:-}" ]; then
      read -r -p "Steam username: " STEAM_USERNAME
    fi

    tmpdir="$(mktemp -d)"
    trap 'rm -rf "$tmpdir"' EXIT

    # Keep DepotDownloader's session data out of the user's home so no token
    # is persisted after the prefetch.
    export HOME="$tmpdir/home"
    export XDG_DATA_HOME="$HOME/.local/share"
    export XDG_CONFIG_HOME="$HOME/.config"
    mkdir -p "$HOME" "$XDG_DATA_HOME" "$XDG_CONFIG_HOME"

    # nix-store --add-fixed uses the basename as the store path name, so it has
    # to match the name of the fixed-output derivation.
    outdir="$tmpdir/${pname}-${version}"
    mkdir -p "$outdir"

    ${depotdownloader'}/bin/DepotDownloader \
      -app ${toString appId} \
      -depot ${toString depotId} \
      -manifest ${toString manifestId} \
      -branch ${lib.escapeShellArg branch} \
      -username "$STEAM_USERNAME" \
      -dir "$outdir"

    rm -rf "$outdir/.DepotDownloader"

    hash="$(nix hash path --algo sha256 "$outdir")"
    store_path="$(nix-store --add-fixed --recursive sha256 "$outdir")"

    echo
    echo "Game files added to: $store_path"
    echo "Recursive hash:      $hash"
    echo
    echo "Pin this hash in the package's derivation:"
    echo "  hash = \"$hash\";"
  '';
}
