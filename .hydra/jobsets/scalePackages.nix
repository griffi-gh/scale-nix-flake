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

  pkgSet = lp."scalePackages${suffix}";
  jobs = lib.filterAttrs (_: lib.isDerivation) pkgSet;
in
jobs
