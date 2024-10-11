# Usage

Add as flake input to use the modules:

```nix
{
  inputs.gameservers.url = "github:timhae/gameservers";
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

All checks have to be ran outside of the sandbox since `steamcmd` requires
internet access to download the game servers. Run them like this:

```nix
nix build --option sandbox false -L .#checks.x86_64-linux.<gameserver>
```

Checks take a long time to complete and download a lot.

# Game Servers

## Stardew Valley

Basic setup:

```nix
services.stardew-server = {
  enable = true;
  openFirewall = true;
};
```

That's it. After a rebuild you can join the game via the IP of your server.
`./modules/stardew-server.nix` defines all available settings.

## Valheim

Basic setup:

```nix
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
```

The systemd unit is not started automatically since the service puts some load
on the host machine and thus enabling with `systemctl start valheim` should be
an active choice. `./modules/valheim-server.nix` defines all available settings.

## Satisfactory



# TODO

- [ ] create checks
- [ ] run ci
- [ ] auto-update flake input
