{ pkgs ? import ./pkgs.nix }:

let
  inherit (pkgs) callPackage;
in rec {
  inherit pkgs;

  status-go = callPackage ./status-go.nix { };
  client = callPackage ./client.nix { inherit status-go; };
}
