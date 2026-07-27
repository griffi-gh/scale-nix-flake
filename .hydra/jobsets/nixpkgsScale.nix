{
  src,
  nixpkgs,
  system ? builtins.currentSystem,
  suffix ? "",
  ...
}:
let
  lib = import "${nixpkgs}/lib";

  flake = import src;
  flake_legacyPackages = flake.legacyPackages.${system};

  packagesData = lib.importJSON ./nixpkgsScale_data/data.json;
  packagesPaths = lib.mapAttrsToListRecursive (path: value: path) packagesData;

  nixpkgs_pkgSet = flake_legacyPackages."nixpkgsScale${suffix}";
  jobs = lib.genAttrs' packagesPaths (
    attrPath:
    {
      name = lib.join "." attrPath;
      value = lib.attrsets.attrByPath attrPath null nixpkgs_pkgSet;
    }
  );
in
jobs
