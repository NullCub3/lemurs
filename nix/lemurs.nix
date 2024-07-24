{ lib
, pam
, pname
, version
, rustPlatform
}:
rustPlatform.buildRustPackage {
  inherit pname version;

  src = ./..;

  buildInputs = [
    pam
  ];

  cargoHash = "sha256-GqIgpDMgXVNtM7SX58ycdOimOqVUbpRqSwprwkfk0d4=";

  meta = with lib; {
    description = "A customizable TUI display/login manager written in Rust";
    homepage = "https://github.com/coastalwhite/lemurs";
    license = with licenses; [ asl20 mit ];
  };
}
