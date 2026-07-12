{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    systems.url = "github:nix-systems/default";
  };

  outputs =
    {
      nixpkgs,
      systems,
      ...
    }:
    let
      inherit (nixpkgs) lib;
      eachSystem = f: lib.genAttrs (import systems) f;

      overlays = import ./nix/overlays { inherit lib; };
      versions = import ./nix/lib/versions.nix { inherit lib; };
    in
    {
      inherit overlays;
      legacyPackages = eachSystem (
        system:
        let
          pkgs = import nixpkgs {
            inherit system;
            config = {
              allowUnfree = true;
              cudaSupport = true;
            };
          };
          scale = pkgs.callPackage ./nix/scalePackages { };

          nixpkgsScale = versions.flattenVersions "nixpkgsScale" (
            lib.genAttrs versions.names (
              name: pkgs.extend overlays."cudaPackages${versions.versionSuffix name}"
            )
          );
        in
        versions.flattenVersions "scalePackages" scale.scaleVersions
        // {
          inherit (scale) mkScaleScope;
        }
        // nixpkgsScale
      );
    };
}
