{
  inputs,
  lib,
  nameSuffix,
  ...
}:
{
  perSystem =
    {
      self',
      pkgs,
      scaleVersions,
      cudaPackagesOverlayFor,
      ...
    }:
    let
      nixpkgsScale_all = lib.mapAttrs' (
        name: scalePackages:
        lib.nameValuePair "nixpkgsScale${nameSuffix name}" (
          import inputs.nixpkgs {
            inherit (pkgs) system config;
            overlays = [
              self'.overlays.scalePackages
              (cudaPackagesOverlayFor scalePackages)
            ];
          }
        )
      ) scaleVersions;
    in
    {
      # (soft-deprecated)
      legacyPackages = nixpkgsScale_all;
    };
}
