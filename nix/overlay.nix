# Override some packages and utilities in 'pkgs'
# and make them available globally via callPackage.
#
# For more details see:
# - https://nixos.wiki/wiki/Overlays
# - https://nixos.org/nixos/nix-pills/callpackage-design-pattern.html

self: super:

let
  inherit (super) callPackage qt514;
in {
  # Custom collection of QT libraries to reduce size
  qtCustom = qt514.env "qt-custom-${qt514.qtbase.version}" (with qt514; [
    qtbase
    qtdeclarative
    qtquickcontrols2
  ]);

  lib = (super.lib or { }) // {
    mkFilter = callPackage ./mkFilter.nix { };
  };
}
