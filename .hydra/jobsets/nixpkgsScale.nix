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

  # TODO: automate this
  packages = [
    "gromacs"
    "colmap"
    "opencv"
    "blender"
    "cudaPackages.saxpy"
  ];

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
