{ lib }:
rec {
  defaultVersion = "latest";
  manifest = import ../scalePackages/data/scaleVersions.nix;
  names = builtins.attrNames manifest;
  versionSuffix = name: lib.optionalString (name != defaultVersion) "_${name}";
  flattenVersions =
    prefix: lib.mapAttrs' (name: v: lib.nameValuePair "${prefix}${versionSuffix name}" v);
}
