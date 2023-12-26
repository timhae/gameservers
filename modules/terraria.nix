{ config, lib, pkgs, inputs, outputs, ... }: {
# TODO: move into gameservers/improve (dynamic user, systemd credentials)
  services.terraria = {
    password = outputs.gitcrypt.gaming.password;
    enable = true;
    worldPath = /var/lib/terraria/default.wld;
    openFirewall = true;
    messageOfTheDay = outputs.gitcrypt.gaming.message;
  };

  users.users.terraria.group = "terraria";

  users.groups.terraria = { };
}
