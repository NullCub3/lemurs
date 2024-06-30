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
    ;
in
{
  options.services.lemurs = rec {
    enable = mkEnableOption "Enable the Lemurs Display Manager";

    x11.enable = mkEnableOption "Enable the X11 part of the Lemurs Display Manager";
    wayland.enable = mkEnableOption "Enable the Wayland part of the Lemurs Display Manager";

    tty = mkOption {
      type = types.str;
      default = "tty2";
    };

    settings = {
      x11 = {
        xauth = mkOption {
          type = types.nullOr types.package;
          default = if x11.enable then pkgs.xorg.xauth else null;
        };

        xorgserver = mkOption {
          type = types.nullOr types.package;
          default = if x11.enable then pkgs.xorg.xorgserver else null;
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

  config = lib.mkIf cfg.enable {
    security.pam.services.lemurs = {
      allowNullPassword = true;
      startSession = true;
      setLoginUid = false;
      enableGnomeKeyring = mkDefault config.services.gnome.gnome-keyring.enable;
    };

    services.displayManager = {
      enable = mkDefault true;
    };

    systemd.defaultUnit = "graphical.target";
    systemd.services = {
      "autovt@${cfg.tty}".enable = false;

      lemurs = {
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
              --xsessions  ${cfg.settings.x11.xsessions} \
              --wlsessions ${cfg.settings.wayland.wayland-sessions}
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
    };

  };
}
