{ lib }:
rec {
  manifest = import ./manifest.nix;

  names = builtins.attrNames manifest;

  defaultVersion = "latest";
  versionSuffix = name: lib.optionalString (name != defaultVersion) "_${name}";

  flattenVersions =
    prefix: lib.mapAttrs' (name: v: lib.nameValuePair "${prefix}${versionSuffix name}" v);
  flattenVersions' = gen: flattenVersions (lib.genAttrs names gen);
}
