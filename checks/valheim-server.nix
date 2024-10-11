{
  self,
}:
{
  name = "valheim-server";
  nodes.server =
    { ... }:
    {
      imports = [ self.nixosModules.valheim-server ];
      nixpkgs.config.allowUnfree = true;
      virtualisation.diskSize = 4096;
      services.valheim = {
        enable = true;
        openFirewall = true;
        passwordFile = "/etc/valheimPassword";
        modifiers = {
          deathpenalty = "casual";
          portals = "casual";
        };
      };
      environment.etc."valheimPassword".text = "PASSWORD=supersecret";
    };
  testScript = ''
    server.start()
    server.systemctl("start valheim.service")
    server.wait_for_unit("valheim.service")
    server.shutdown()
  '';
}
