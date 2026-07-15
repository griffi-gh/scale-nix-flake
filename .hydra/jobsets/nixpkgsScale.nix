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
    "cudaPackages.saxpy"
  ];

  groups = lib.filter (n: lib.hasPrefix "nixpkgsScale" n) (lib.attrNames lp);
  jobs = lib.genAttrs groups (
    g:
    let
      attrPath = lib.splitString "." lp.${g};
    in
    lib.genAttrs packages (p: lib.attrsets.attrByPath p null attrPath)
  );
in
jobs
