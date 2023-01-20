{ config, lib, pkgs, ... }:
let
  cfg = config.services.stardew-server;
in
with lib; {
  options = {
    services.stardew-server = {
      enable = mkEnableOption "enable stardew-server";
    };
  };
  config = mkIf cfg.enable {
    age = {
      secrets = {
        borgPW.file = ../secrets/borgPW.age;
      };
    };
  };
}
