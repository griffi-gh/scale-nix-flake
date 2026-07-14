{
  # projectName,
  # declInput,
  nixpkgs,
  system ? builtins.currentSystem,
  ...
}:
let
  pkgs = import nixpkgs { inherit system; };
  inherit (pkgs) lib;

  mkJobset =
    {
      path,
      description ? "",
    }:
    {
      inherit description;
      enabled = 1;
      hidden = false;
      type = 0; # legacy
      nixexprinput = "src";
      nixexprpath = path;
      checkinterval = 1800;
      schedulingshares = 1;
      enableemail = false;
      emailoverride = "";
      keepnr = 500;
      inputs = {
        src = {
          type = "git";
          value = "https://github.com/griffi-gh/scale-nix-flake.git master";
          emailresponsible = false;
        };
        nixpkgs = {
          type = "git";
          value = "https://github.com/NixOS/nixpkgs.git nixos-unstable";
          emailresponsible = false;
        };
      };
    };

  jobsets = lib.mapAttrs (name: mkJobset) {
    scalePackages = {
      description = "All SCALE packages";
      path = ".hydra/jobsets/scalePackages.nix";
    };
    nixpkgsScale = {
      description = "Nixpkgs packages w/ SCALE cudaPackages";
      path = ".hydra/jobsets/nixpkgsScale.nix";
    };
  };
in
{
  jobsets = pkgs.writers.writeJSON "jobsets.json" jobsets;
}
