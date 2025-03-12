{
  config,
  pkgs,
  lib,
  ...
}:
{
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
      ExecStart = "${
        pkgs.resholve.writeScript "steam"
          {
            interpreter = "${pkgs.zsh}/bin/zsh";
            inputs = with pkgs; [
              patchelf
              steamcmd
            ];
            execer = with pkgs; [ "cannot:${steamcmd}/bin/steamcmd" ];
          }
          ''
            set -eux

            instance=''${1:?Instance Missing}
            eval 'args=(''${(@s:_:)instance})'
            app=''${args[1]:?App ID missing}
            windows=''${args[2]:-}

            dir=/var/lib/steam-app-$instance

            cmds=(
              +force_install_dir $dir
            )

            if [[ $windows ]]; then
              cmds+=(+@sSteamCmdForcePlatformType windows)
            fi

            cmds+=(
              +login anonymous
              +app_update $app validate
            )

            cmds+=(+quit)

            steamcmd $cmds

            for f in $dir/*; do
              if ! [[ -f $f && -x $f ]]; then
                continue
              fi

              # Update the interpreter to the path on NixOS.
              patchelf --set-interpreter ${pkgs.glibc}/lib/ld-linux-x86-64.so.2 $f || true
            done
          ''
      } %i";
      PrivateTmp = true;
      Restart = "on-failure";
      StateDirectory = "steam-app-%i";
      TimeoutStartSec = 3600; # Allow time for updates.
      User = "steam";
      WorkingDirectory = "~";
    };
  };
}
