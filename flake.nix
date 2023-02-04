{
  description = "Gameservers for various games";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.11";
  };
  outputs = { self, nixpkgs }:
    let
      callPackage = nixpkgs.legacyPackages.x86_64-linux.callPackage;
    in
    {
      packages.x86_64-linux = {
        stardew-server = callPackage ./pkgs/stardew-server.nix { };
        test-mod = callPackage ./pkgs/test-mod.nix { };
      };
      nixosModules = {
        stardew-server = import ./module/stardew-server.nix;
      };
    };
}
