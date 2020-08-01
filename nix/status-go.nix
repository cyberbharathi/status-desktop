{ buildGoPackage, lib, go }:

let
  inherit (lib) concatStringsSep concatMapStrings fileContents;

  removeReferences = [ go ];
  removeExpr = refs: ''remove-references-to ${concatMapStrings (ref: " -t ${ref}") refs}'';

in buildGoPackage rec {
  pname = "status-go";
  version = fileContents ./../vendor/status-go/VERSION;
  goPackagePath = "github.com/status-im/status-go";

  src = builtins.path {
    name = "status-go-source";
    path = ./../vendor/status-go;
    filter = lib.mkFilter {
      root = ./../vendor/status-go;
      include = [ ".*" ];
      exclude = [
        "_assets/.*" "build/.*"
        ".*/[.]git.*" ".*[.]md" ".*[.]yml" ".*/.*_test.go$"
        ".*/.*LICENSE.*" ".*/CONTRIB.*" ".*/AUTHOR.*"
      ];
    };
  };
 
  preBuild = ''
    cd "$NIX_BUILD_TOP/go/src/${goPackagePath}" 
    mkdir -p ./build/bin/statusgo-lib
    go run cmd/library/*.go > ./build/bin/statusgo-lib/main.go
  '';

  buildPhase = let
    buildFlags = [
      "-X github.com/status-im/status-go/params.Version=${version}"
      "-X github.com/status-im/status-go/params.GitCommit=${version}"
      "-X github.com/status-im/status-go/vendor/github.com/ethereum/go-ethereum/metrics.EnabledStr=true"
    ];
  in ''
    runHook preBuild

    mkdir -p $out
    go build \
      -ldflags='${concatStringsSep " " buildFlags}' \
      -buildmode=c-archive \
      -o $out/libstatus.a \
      ./build/bin/statusgo-lib
  '';

  # replace hardcoded paths to go package in /nix/store, otherwise Nix will fail the build
  fixupPhase = ''
    find $out -type f -exec ${removeExpr removeReferences} '{}' + || true
  '';

  installPhase = ''
    mkdir -p $out/lib $out/include
    mv $out/libstatus.a $out/lib/
    mv $out/libstatus.h $out/include
  '';

  outputs = [ "out" ];
}
