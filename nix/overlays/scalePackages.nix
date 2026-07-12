final: prev:
let
  inherit (prev) lib;
  versions = import ../lib/versions.nix { inherit lib; };
  scale = final.callPackage ../scalePackages { };
in
{
  inherit (scale) mkScaleScope scaleVersions;
}
// versions.flattenVersions "scalePackages" (
  lib.genAttrs versions.names (name: scale.scaleVersions.${name})
)
