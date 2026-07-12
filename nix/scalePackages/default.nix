{
  lib,
  nameSuffix,
  ...
}:
{
  imports = [
    ./mkScaleScope.nix
    ./scaleVersions.nix
  ];

  perSystem =
    {
      mkScaleScope,
      scaleVersions,
      ...
    }:
    let
      scalePackages_all =
        (lib.mapAttrs' (
          name: scalePackages: lib.nameValuePair "scalePackages${nameSuffix name}" scalePackages
        ) scaleVersions)
        // {
          inherit mkScaleScope;
        };
      # scalePackages_overlay = (final: prev: scalePackages_all);
    in
    {
      legacyPackages = scalePackages_all;
      # overlays.scalePackages = scalePackages_overlay;
    };
}
