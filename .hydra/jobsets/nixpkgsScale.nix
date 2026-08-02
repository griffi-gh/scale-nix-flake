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

  packagesData = lib.importJSON ./nixpkgsScale_data/data.json;
  packagesPaths = lib.mapAttrsToListRecursive (path: value: path) packagesData;

  sourcePkgs = import nixpkgs {
    inherit system;
    __allowFileset = true;
    config = {
      allowAliases = true; # XXX: should this be off
      allowUnfree = true;
      allowBroken = false;
      allowInsecure = true;
      cudaSupport = true;
      cudaCapabilities = [ "8.6" ]; # TODO: handle this in the overlay instead
      inHydra = true;
    };
    overlays = [
      flake.overlays.scalePackages
      flake.overlays."cudaPackages${suffix}"
    ];
  };

  jobs = lib.genAttrs' packagesPaths (
    attrPath:
    {
      name = lib.join "." attrPath;
      value = lib.attrsets.attrByPath attrPath null sourcePkgs;
    }
  );
in
jobs
