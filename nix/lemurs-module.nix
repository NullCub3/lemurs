{ pkgs, lib, config, ... }:


let
  cfg = config.services.lemurs;

  sessionData = config.services.displayManager.sessionData.desktops.outPath;

  settingsFormat = pkgs.formats.toml { };

  defaultToml = (lib.importTOML ../extra/config.toml);
  mergedSettings = lib.recursiveUpdate defaultToml cfg.settings;
  settingsFile = settingsFormat.generate "config.toml" mergedSettings;

  inherit (lib)
    mkEnableOption
    mkOption
    mkDefault
    types
    ;
in
{
  options.services.lemurs = {
    enable = mkEnableOption "Enable the Lemurs Display Manager";

    x11.enable = mkEnableOption "Enable the X11 part of the Lemurs Display Manager";
    wayland.enable = mkEnableOption "Enable the Wayland part of the Lemurs Display Manager";

    tty = mkOption {
      type = types.str;
      default = "tty${builtins.toString (defaultToml.tty)}";
    };

    settings = {
      x11 = {
        xauth_path = mkOption {
          type = types.path;
          default = "${pkgs.xorg.xauth}/bin/xauth";
        };

        xserver_path = mkOption {
          type = types.path;
          default = "${pkgs.xorg.xorgserver}/bin/X";
        };

        xsessions_path = mkOption {
          type = types.path;
          default = "${sessionData}/share/xsessions";
        };
      };
      wayland = {
        wayland_sessions_path = mkOption {
          type = types.path;
          default = "${sessionData}/share/wayland-sessions";
        };
      };
    };

  };

  config = lib.mkIf cfg.enable {
    # nixpkgs.overlays = [
    #   (final: prev: { lemurs = ./..#lemurs; })
    # ];

    services.displayManager.enable = true;

    security.pam.services.lemurs = {
      allowNullPassword = true;
      startSession = true;
      setLoginUid = false;
      enableGnomeKeyring = mkDefault config.services.gnome.gnome-keyring.enable;
    };

    systemd.services."autovt@${cfg.tty}".enable = false;

    systemd.services.lemurs = {
      aliases = [ "display-manager.service" ];

      unitConfig = {
        Wants = [
          "systemd-user-sessions.service"
        ];

        After = [
          "systemd-user-sessions.service"
          "plymouth-quit-wait.service"
          "getty@${cfg.tty}.service"
        ];

        Conflicts = [
          "getty@${cfg.tty}.service"
        ];
      };

      serviceConfig = {
        ExecStart = ''
          ${pkgs.lemurs}/bin/lemurs \
            --xsessions  ${cfg.settings.x11.xsessions_path} \
            --wlsessions ${cfg.settings.wayland.wayland_sessions_path} \
            --config ${settingsFile}
        '';

        StandardInput = "tty";
        TTYPath = "/dev/${cfg.tty}";
        TTYReset = "yes";
        TTYVHangup = "yes";

        Type = "idle";
      };

      restartIfChanged = false;

      wantedBy = [ "graphical.target" ];
    };

    systemd.defaultUnit = "graphical.target";
  };
}

