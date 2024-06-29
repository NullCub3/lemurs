{ lib
, pkgs
, linux-pam
, packageName
, rustPlatform
}:
rustPlatform.buildRustPackage {
  name = packageName;
  # version = "0.3.2";

  src = ./..;

  # postPatch = ''
  #   substituteInPlace ./extra/config.toml --replace "/bin/sh" "${pkgs.bash}/bin/bash"
  #   substituteInPlace ./extra/config.toml --replace "/usr/bin/X" "${pkgs.xorg.xorgserver}/bin/X"
  #   substituteInPlace ./extra/config.toml --replace "/usr/bin/xauth" "${pkgs.xorg.xauth}/bin/xauth"
  # '';

  buildInputs = [
    linux-pam
  ];

  cargoHash = "sha256-rJLHfedg4y8cZH77AEA4AjE0TvWf9tdSjKiHZfvW+gw=";

  meta = with lib; {
    description = "A customizable TUI display/login manager written in Rust";
    homepage = "https://github.com/coastalwhite/lemurs";
    license = with licenses; [ asl20 mit ];
  };
}
