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
    lib.genAttrs packages (
      p:
      let
        attrPath = lib.splitString "." p;
      in
      lib.attrsets.attrByPath attrPath null lp.${g}
    )
  );
in
jobs
