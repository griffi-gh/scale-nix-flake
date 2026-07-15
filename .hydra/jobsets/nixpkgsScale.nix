{
  src,
  nixpkgs,
  system ? builtins.currentSystem,
  suffix ? "",
  ...
}:
let
  lib = import "${nixpkgs}/lib";

  # THIS IS BORROWED/ADAPTED FROM
  # https://github.com/nixos-cuda/hydra-jobsets/blob/master/jobsets/cuda-packages.nix
  # (thanks ^w^)
  ci = import "${nixpkgs}/ci" {
    inherit system nixpkgs;
  };
  nixpkgsConfig = {
    allowUnfree = true;
    cudaSupport = true;
    inHydra = true;
    allowAliases = false;
  };
  evalCudaSupportFalse = ci.eval {
    extraNixpkgsConfig = nixpkgsConfig // {
      cudaSupport = false;
    };
  };
  evalCudaSupportTrue = ci.eval {
    extraNixpkgsConfig = nixpkgsConfig;
  };
  getAttrs =
    dir:
    let
      raw = builtins.readFile "${dir}/${system}/paths.json";
      data = builtins.unsafeDiscardStringContext raw;
    in
    builtins.fromJSON data;
  before = getAttrs (evalCudaSupportFalse.baseline { evalSystems = [ system ]; });
  after = getAttrs (evalCudaSupportTrue.baseline { evalSystems = [ system ]; });
  isAddedOrChanged = name: !(before ? ${name}) || after.${name} != before.${name};
  changed = lib.filter isAddedOrChanged (lib.attrNames after);
  attrPaths = map (path: lib.init (lib.splitString "." path)) changed;

  flake = import src;
  pkgSet = flake.legacyPackages.${system}."nixpkgsScale${suffix}";
  jobs = lib.foldl' (
    acc: path:
    let
      name = lib.concatStringsSep "." path;
      value = lib.attrByPath path null pkgSet;
    in
    if value == null then acc else acc // { ${name} = value; }
  ) { } attrPaths;
in
jobs
