{
  description = "Gameservers for various games";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.11";
  };
  outputs = { self, nixpkgs }: {
    packages.x86_64-linux.stardew-server = nixpkgs.legacyPackages.x86_64-linux.callPackage ./pkgs/stardew-server.nix { };
    nixosModules.stardew-server = import ./module/stardew-server.nix;
  };
}
