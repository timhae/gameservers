# Usage

Add as flake input to use the module:

```nix
{
  inputs.gameservers.url = "github:timhae/gameservers";
  inputs.gameservers.inputs.nixpkgs.follows = "nixos";
  inputs.nixos.url = "github:NixOS/nixpkgs/nixos-22.11";
  outputs = { self, nixos, gameservers }: {
    nixosConfigurations.myMachine = nixos.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        gameservers.nixosModules.<gameserver>
      ];
    };
  };
}
```

# Game Servers

## Stardew Valley

Basic setup:

```nix
services.stardew-server = {
  enable = true;
  openFirewall = true;
};
```

That's it. After a rebuild you can join the game via the IP of your server. `modules/stardew-server.nix` defines all available settings.
