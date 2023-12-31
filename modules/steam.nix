{ config, pkgs, lib, ... }: {
  users.users.steam = {
    isSystemUser = true;
    group = "steam";
    home = "/var/lib/steam";
    createHome = true;
  };

  users.groups.steam = { };

  systemd.services."steam@" = {
    unitConfig = {
      StopWhenUnneeded = true;
    };
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.resholve.writeScript "steam" {
        interpreter = "${pkgs.zsh}/bin/zsh";
        inputs = with pkgs; [
          patchelf
          steamcmd
          coreutils
        ];
        execer = with pkgs; [
          "cannot:${steamcmd}/bin/steamcmd"
        ];
      } ''
        set -eux

        instance=''${1:?Instance Missing}
        eval 'args=(''${(@s:_:)instance})'
        app=''${args[1]:?App ID missing}
        beta=''${args[2]:-}
        betapass=''${args[3]:-}

        dir=/var/lib/steam-app-$instance

        cmds=(
          +force_install_dir $dir
          +login anonymous
          +app_update $app validate
        )

        if [[ $beta ]]; then
          cmds+=(-beta $beta)
          if [[ $betapass ]]; then
            cmds+=(-betapassword $betapass)
          fi
        fi

        cmds+=(+quit)

        steamcmd $cmds

        for f in $dir/*; do
          if ! [[ -f $f && -x $f ]]; then
            continue
          fi

          # Update the interpreter to the path on NixOS.
          patchelf --set-interpreter ${pkgs.glibc}/lib/ld-linux-x86-64.so.2 $f || true
        done
        chmod -R 777 /var/lib/steam-app-$instance
      ''} %i";
      PrivateTmp = true;
      Restart = "on-failure";
      StateDirectory = "steam-app-%i";
      TimeoutStartSec = 3600; # Allow time for updates.
      User = "steam";
      WorkingDirectory = "~";
    };
  };
}
