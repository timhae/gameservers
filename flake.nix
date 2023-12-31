{
  description = "Gameservers and modules";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.05";
  };
  outputs = { self, nixpkgs }:
    let
      supportedSystems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      nixpkgsFor = forAllSystems (system: import nixpkgs { inherit system; overlays = [ self.overlays.default ]; });
      version = builtins.substring 0 8 self.lastModifiedDate;
    in
    {
      overlays.default = final: _: {
        stardew-server = final.callPackage ./pkgs/stardew-server.nix { };
        terraria-server = final.callPackage ./pkgs/terraria-server.nix { };
        tmod-server = final.callPackage ./pkgs/tmod-server.nix { };
        test-mod = final.callPackage ./pkgs/test-mod.nix { };
        mage-server = final.callPackage ./pkgs/mage-server.nix { };
      };
      packages = forAllSystems (system: {
        inherit (nixpkgsFor.${system}) stardew-server terraria-server test-mod;
      });
      nixosModules = {
        stardew-server = import ./modules/stardew-server.nix;
        terraria-server = import ./modules/terraria-server.nix;
        valheim-server = import ./modules/valheim.nix;
        mage-server = import ./modules/mage-server.nix;
      };
      homeManagerModules = {
        valheim-mods = import ./modules/valheim-mods.nix;
      };
      # checks = forAllSystems (system:
      #   self.packages.${system} // import ./checks/terraria-server.nix { inherit self nixpkgs system; }
      #   self.packages.${system} // import ./checks/tmod-server.nix { inherit self nixpkgs system; }
      # );
      formatter = forAllSystems (system: nixpkgsFor.${system}.nixpkgs-fmt);
    };
}
