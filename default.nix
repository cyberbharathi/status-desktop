let
  main = import ./nix { };
in {
  # this is where the --attr argument selects the shell or target
  inherit (main) pkgs;
  inherit main;
}
