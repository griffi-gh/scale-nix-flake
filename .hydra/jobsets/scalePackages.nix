{ src, nixpkgs, ... }:
let
  system = "x86_64-linux";
  pkgs = import nixpkgs { inherit system; };
  inherit (pkgs) lib;

  flake = import src;
  lp = flake.legacyPackages.${system};

  groups = lib.filter (n: lib.hasPrefix "scalePackages" n) (lib.attrNames lp);
  jobs = lib.genAttrs groups (g: lib.filterAttrs (_: lib.isDerivation) lp.${g});
  allDrvs = lib.concatMap (g: lib.attrValues jobs.${g}) groups;
in
jobs
// {
  aggregate = pkgs.releaseTools.aggregate {
    name = "scalePackages";
    constituents = allDrvs;
    meta.description = "All SCALE packages";
  };
}
