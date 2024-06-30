{ config, pkgs, lib, ... }:
let
  cfg = config.services.lemurs;
  sessionData = config.services.displayManager.sessionData.desktops.outPath;
  settingsFormat = pkgs.formats.toml { };
  defaultConfig = lib.importTOML ../extra/config.toml;
  inherit (lib)
    mkDefault
    mkEnableOption
    mkOption
    types
    mkIf
    ;
in
{
  options.services.lemurs = rec {
    enable = mkEnableOption "Enable the Lemurs Display Manager";

    x11.enable = mkEnableOption "Enable the X11 part of the Lemurs Display Manager";
    wayland.enable = mkEnableOption "Enable the Wayland part of the Lemurs Display Manager";

    tty = mkOption {
      type = types.int;
      default = 2;
    };

    shell = mkOption {
      type = types.str;
      default = "${pkgs.bash}/bin/bash";
      # default = config.users.defaultUserShell;
      description = ''
        The shell that lemurs uses to run commands
      '';
    };

    settings = {
      x11 = {
        xauth = mkOption {
          type = with types; nullOr package;
          default = if cfg.x11.enable then pkgs.xorg.xauth else null;
        };

        xorgserver = mkOption {
          type = with types; nullOr package;
          default = if cfg.x11.enable then pkgs.xorg.xorgserver else null;
        };

        xsessions = mkOption {
          type = types.path;
          default = "${sessionData}/share/xsessions";
        };
      };

      wayland = {
        wayland-sessions = mkOption {
          type = types.path;
          default = "${sessionData}/share/wayland-sessions";
        };
      };
    };

    extraSettings = mkOption {
      type = settingsFormat.type;
      example = lib.literalExpression /*nix*/ ''
        {
          do_log = true;
          cache_path = "/var/cache/lemurs";
          background = {
            show_background = true;
          };
        }
      '';
      default = { };
      description = ''
        Extra configuration to be applied to [config.toml](https://github.com/coastalwhite/lemurs/blob/main/extra/config.toml)
        as a nix attribute set
      '';
    };
  };

  config =
    let
      lemursConfig = lib.recursiveUpdate defaultConfig (lib.recursiveUpdate
        (cfg.extraSettings)
        {
          tty = cfg.tty;
          system_shell = cfg.shell;
          x11 =
            if cfg.x11.enable then {
              xauth_path = "${cfg.settings.x11.xauth}/bin/xauth";
              xserver_path = "${cfg.settings.x11.xorgserver}/bin/X";
              xsessions_path = cfg.x11.settings.xsessions;
            } else { };
          wayland =
            if cfg.wayland.enable then {
              wayland_sessions_path = cfg.settings.wayland.wayland-sessions;
            } else { };
        });

      tty = "tty${builtins.toString (cfg.tty)}";
    in
    lib.mkIf cfg.enable {
      security.pam.services.lemurs = {
        allowNullPassword = true;
        startSession = true;
        setLoginUid = false;
        enableGnomeKeyring = mkDefault config.services.gnome.gnome-keyring.enable;
      };

      services.displayManager = {
        enable = mkDefault true;
      };

      environment.etc = {
        "lemurs/config.toml" = {
          source = (settingsFormat.generate "lemurs-config.toml" lemursConfig);
          mode = "0644";
        };
      };

      systemd.defaultUnit = "graphical.target";
      systemd.services = {
        "autovt@${tty}".enable = false;

        lemurs = {
          aliases = [ "display-manager.service" ];

          unitConfig = {
            Wants = [
              "systemd-user-sessions.service"
            ];

            After = [
              "systemd-user-sessions.service"
              "plymouth-quit-wait.service"
              "getty@${tty}.service"
            ];

            Conflicts = [
              "getty@${tty}.service"
            ];

            path = [
              # pkgs.systemd
              # pkgs.coreutils
            ];
          };

          serviceConfig = {
            ExecStart = ''
              ${pkgs.lemurs}/bin/lemurs \
                --xsessions  ${cfg.settings.x11.xsessions} \
                --wlsessions ${cfg.settings.wayland.wayland-sessions}
            '';
            StandardInput = "tty";
            TTYPath = "/dev/${tty}";
            TTYReset = "yes";
            TTYVHangup = "yes";
            Type = "idle";
          };
          restartIfChanged = false;
          wantedBy = [ "graphical.target" ];
        };
      };

    };
}
