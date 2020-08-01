# This file controls the pinned version of nixpkgs we use for our Nix environment
# as well as which versions of package we use, including their overrides.
let
  inherit (import <nixpkgs> { }) fetchFromGitHub;

  # For testing local version of nixpkgs
  #nixpkgsSrc = (import <nixpkgs> { }).lib.cleanSource "/home/jakubgs/work/nixpkgs";

  # Our own nixpkgs fork with custom fixes
  nixpkgsSrc = fetchFromGitHub {
    name = "nixpkgs-source";
    owner = "nixos";
    repo = "nixpkgs";
    rev = "f2be6bd91a7f2bcbcd625a82f66617b52497161d";
    sha256 = "0c1lyc6sqh39z7wwmi1vvfwwzlwhr1m387ncp92braqvg5fkkvpg";
    # To get the compressed Nix sha256, use:
    # nix-prefetch-url --unpack https://github.com/${ORG}/nixpkgs/archive/${REV}.tar.gz
  };

  # Override some packages and utilities
  pkgsOverlay = import ./overlay.nix;
in
  # import nixpkgs with a config override
  (import nixpkgsSrc) {
    overlays = [ pkgsOverlay ];
  }
