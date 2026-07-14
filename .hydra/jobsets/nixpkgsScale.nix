{ src, nixpkgs, ... }:
let
  system = "x86_64-linux";
  pkgs = import nixpkgs { inherit system; };
  inherit (pkgs) lib;

  flake = import src;
  lp = flake.legacyPackages.${system};

  # TODO: automate this
  packages = [
    "gromacs"
    "colmap"
    "opencv"
    "blender"
  ];

  groups = lib.filter (n: lib.hasPrefix "nixpkgsScale" n) (lib.attrNames lp);
  jobs = lib.genAttrs groups (g: lib.genAttrs packages (p: lp.${g}.${p}));
  allDrvs = lib.concatMap (g: lib.attrValues jobs.${g}) groups;
in
jobs
// {
  aggregate = pkgs.releaseTools.aggregate {
    name = "scaleNixpkgs";
    constituents = allDrvs;
    meta.description = "Nixpkgs packages w/ SCALE cudaPackages";
  };
}
