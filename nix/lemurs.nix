{ lib
, pam
, packageName
, rustPlatform
}:
rustPlatform.buildRustPackage {
  name = packageName;
  # version = "0.3.2";

  src = ./..;

  buildInputs = [
    pam
  ];

  cargoHash = "sha256-rJLHfedg4y8cZH77AEA4AjE0TvWf9tdSjKiHZfvW+gw=";

  meta = with lib; {
    description = "A customizable TUI display/login manager written in Rust";
    homepage = "https://github.com/coastalwhite/lemurs";
    license = with licenses; [ asl20 mit ];
  };
}
