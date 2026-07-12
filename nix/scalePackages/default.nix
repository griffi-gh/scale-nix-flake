{
  lib,
  callPackage,
  fetchurl,
  requireFile,
}:
let
  versions = import ../lib/versions.nix { inherit lib; };

  mkScaleScope = callPackage ./mkScaleScope.nix { };

  fetchers = { inherit fetchurl requireFile; };
  mkSrc = source: fetchers.${source._type} (removeAttrs source [ "_type" ]);
  mkScopeArg =
    meta:
    (removeAttrs meta [ "source" ])
    // {
      license = meta.license or import ./license/scaleFreeLicense.nix;
      src = mkSrc meta.source;
    };
  scaleVersions = lib.mapAttrs (_: meta: mkScaleScope (mkScopeArg meta)) versions.manifest;
in
{
  inherit mkScaleScope scaleVersions;
}
