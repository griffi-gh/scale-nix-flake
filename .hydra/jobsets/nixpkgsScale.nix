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
  lp = flake.legacyPackages.${system};

  packagesData = lib.importJSON ./nixpkgsScale_data/data.json;
  packages = lib.mapAttrsToListRecursive (path: value: "${path}") packagesData;

  # TODO: automate this
  # packages = [
  #   "gromacs"
  #   "colmap"
  #   "opencv"
  #   "blender"
  #   "cudaPackages.saxpy"
  # ];

  pkgSet = lp."nixpkgsScale${suffix}";
  jobs = lib.genAttrs packages (
    p:
    let
      attrPath = lib.splitString "." p;
    in
    lib.attrsets.attrByPath attrPath null pkgSet
  );
in
jobs
