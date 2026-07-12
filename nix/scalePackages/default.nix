{
  lib,
  callPackage,
  fetchurl,
  requireFile,
}:
let
  mkScaleScope = callPackage ./mkScaleScope.nix { };
  versions = import ./data/scaleVersions.nix;

  fetchers = { inherit fetchurl requireFile; };
  mkSrc = source: fetchers.${source._type} (removeAttrs source [ "_type" ]);
  scaleVersions = lib.mapAttrs (
    _: meta:
    mkScaleScope (
      (removeAttrs meta [ "source" ])
      // {
        license = meta.license or import ./license/scaleFreeLicense.nix;
        src = mkSrc meta.source;
      }
    )
  ) versions;
in
{
  inherit mkScaleScope versions scaleVersions;
}
