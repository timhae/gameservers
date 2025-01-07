{
  description = "Gameservers and Home-Manager/NixOS modules";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  outputs =
    { self, nixpkgs }:
    let
      forEachSystem = nixpkgs.lib.genAttrs [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forEachPkgs = f: forEachSystem (system: f nixpkgs.legacyPackages.${system});
      nixos-lib = import "${nixpkgs}/nixos/lib" { };
      mkTest =
        {
          name,
          testScript,
          nodes,
          pkgs,
          ...
        }:
        nixos-lib.runTest {
          inherit name testScript nodes;
          hostPkgs = pkgs;
          passthru = {
            ci = false;
          };
        };
    in
    {
      overlays.default = final: _: {
        #mage-server = final.callPackage ./pkgs/mage-server.nix { };
        stardew-server = final.callPackage ./pkgs/stardew-server.nix { };
        terraria-server = final.callPackage ./pkgs/terraria-server.nix { };
        test-mod = final.callPackage ./pkgs/test-mod.nix { };
        tmod-server = final.callPackage ./pkgs/tmod-server.nix { };
      };
      packages = forEachPkgs (pkgs: (self.overlays.default pkgs pkgs));
      nixosModules = {
        #mage-server = import ./modules/mage-server.nix;
        stardew-server = import ./modules/stardew-server.nix;
        terraria-server = import ./modules/terraria-server.nix;
        valheim-server = import ./modules/valheim-server.nix;
        satisfactory-server = import ./modules/satisfactory-server.nix;
        vrising-server = import ./modules/vrising-server.nix;
      };
      homeManagerModules = {
        valheim-mods = import ./modules/valheim-mods.nix;
      };
      formatter = forEachPkgs (pkgs: pkgs.nixfmt-rfc-style);
      checks = forEachPkgs (pkgs: {
        valheim-server = mkTest ((import ./checks/valheim-server.nix { inherit self; }) // pkgs);
      });
    };
}
