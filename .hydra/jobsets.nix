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

  versions = import ../nix/lib/versions.nix { inherit lib; };

  mkString = value: {
    type = "string";
    inherit value;
  };

  mkJobset =
    {
      path,
      description ? "",
      inputs ? { },
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
      }
      // inputs;
    };

  jobsets = lib.mapAttrs (name: mkJobset) (
    (versions.flattenVersionsAll "scalePackages" (version: {
      description = "All SCALE packages (${version})";
      path = ".hydra/jobsets/scalePackages.nix";
      inputs.suffix = mkString (versions.versionSuffix version);
    }))
    // (versions.flattenVersionsAll "nixpkgsScale" (version: {
      description = "Nixpkgs packages w/ SCALE cudaPackages (${version})";
      path = ".hydra/jobsets/nixpkgsScale.nix";
      inputs.suffix = mkString (versions.versionSuffix version);
    }))
  );
in
{
  jobsets = pkgs.writers.writeJSON "jobsets.json" jobsets;
}
