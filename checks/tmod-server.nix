{
  self,
  nixpkgs,
  system,
}:
{
  terraria-server =
    with import (nixpkgs + "/nixos/lib/testing-python.nix") { inherit system; };
    makeTest {
      name = "terraria-server";
      nodes.server = {
        imports = [ self.nixosModules.terraria-server ];
        nixpkgs.overlays = [ self.overlays.default ];
        services.terraria-server = {
          enable = true;
          autoCreatedWorldSize = "small";
          openFirewall = true;
        };
      };
      testScript = ''
        server.wait_for_unit("terraria-server.service")
        server.wait_for_open_port(7777)
        server.shutdown()
      '';
    };
}
