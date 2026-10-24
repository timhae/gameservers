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

The game files are a fixed-output derivation that uses DepotDownloader to
fetch the Linux depot of Stardew Valley 1.5.6. Steam does not serve paid apps
to anonymous accounts, so fetching them needs credentials of an account that
owns the game.

The local workflow is to prefetch the files with:

```sh
nix run .#prefetch-stardew-valley
```

It asks for your Steam username; DepotDownloader then prompts for the password
and Steam Guard. The credentials are only used by that DepotDownloader process
and never reach Nix. The script adds the downloaded files to the Nix store and
prints the recursive hash. Replace `hash = lib.fakeHash;` in the `src`
derivation in `./pkgs/stardew-server.nix` with the printed hash, then build
normally:

```sh
nix build .#stardew-server
```

The fixed-output derivation can also fetch the depot by itself for unattended
builds. It reads `STEAM_USERNAME`, `STEAM_PASSWORD` and `STEAM_GUARD_CODE`.

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

Basic setup:

```nix
services.satisfactory = {
  enable = true;
  openFirewall = true;
};
```

The systemd unit is not started automatically since the service puts some load
on the host machine and thus enabling with `systemctl start satisfactory` should
be an active choice. `./modules/satisfactory-server.nix` defines all available
settings. Make sure to claim the server through the server manager in the
starting screen of the game after you start the service.

# TODO

- [ ] create checks
- [ ] run ci
- [ ] auto-update flake input
- [x] package Stardew Valley server files with depot downloader
- [x] pin Stardew Valley depot hash
- [ ] package remaining server files with depot downloader
