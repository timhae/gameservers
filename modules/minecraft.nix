{ config, lib, pkgs, inputs, outputs, ... }: {
  services.minecraft-server = {
    enable = true;
    eula = true;
    declarative = true;
    openFirewall = true;
    serverProperties = {
      server-port = 25565;
      gamemode = "survival";
      max-players = 5;
      white-list = true;
      enable-rcon = true;
      "rcon.password" = outputs.gitcrypt.minecraft.rconPW;
      "rcon.port" = 25575;
      broadcast-rcon-to-ops = false;
    };
    whitelist = {
    };
  };
}
