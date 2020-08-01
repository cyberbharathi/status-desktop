{ callPackage, stdenv, lib
# Build dependencies
, qtCustom, pkgs
# The whisper/waku library
, status-go
# Additional custom parameters
, nimParams ? [ ] }:

let
  inherit (lib) concatStringsSep;


in stdenv.mkDerivation {
  pname = "nim-status-client";
  version = "1.0.0-alpha"; # TODO

  src = builtins.path {
    name = "nim-status-client-source";
    path = ./..;
    filter = lib.mkFilter {
      root = ./..;
      include = [
        "Makefile" "nim.cfg" "config.nims"
        "src/.*" "vendor/.*"
      ];
      exclude = [
        "vendor/.nimble/.*" ".*/vendor/status-go/.*"
        ".*/nimbus-build-system/vendor/.*"
      ];
    };
  };
  
  buildInputs = with pkgs; [ nim git pkgconfig which ];
  propagatedBuildInputs = with pkgs; [ openssl pcre qtCustom ];

  QTDIR = qtCustom;
  QT5_PCFILEDIR = "${qtCustom}/lib/pkgconfig";
  QT5_LIBDIR = "${qtCustom}/lib";

  phases = [ "unpackPhase" "configurePhase" "buildPhase" "installPhase"];
  
  # Generate vendor/.nimble contents with correct paths
  configurePhase = ''
    export NIMBLE_LINK_SCRIPT=$PWD/vendor/nimbus-build-system/scripts/create_nimble_link.sh
    export NIMBLE_DIR=$PWD/vendor/.nimble
    export PWD_CMD=$(which pwd)
    patchShebangs $NIMBLE_LINK_SCRIPT
    for dep_dir in $(find vendor -type d -maxdepth 1); do
        pushd "$dep_dir"
        $NIMBLE_LINK_SCRIPT "$dep_dir"
        popd
    done
  '';

  buildPhase = ''
    nim c ${concatStringsSep " " nimParams} \
      --passL:"${status-go}/lib/libstatus.a" \
      --passL:"vendor/QR-Code-generator/c/libqrcodegen.a" \
      --passL:"-lsetupapi -lhid" \
      --passL:"-lm" \
      --passL:"-lpcre" \
      -d:usePcreHeader \
      src/nim_status_client.nim
  '';

  installPhase = ''
    mkdir -p $out/bin
    cp ./bin/nim_status_client $out/bin/
  '';
}
