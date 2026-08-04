{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    systems.url = "github:nix-systems/default";
    flake-compat = {
      url = "github:NixOS/flake-compat";
      flake = false;
    };
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
              allowBroken = false;
              allowInsecure = true;
              cudaSupport = true;
              cudaCapabilities = [ "8.6" ]; # TODO: handle this in the overlay instead
            };
          };
          scale = pkgs.callPackage ./nix/scalePackages { };

          nixpkgsScale = versions.flattenVersions "nixpkgsScale" (
            lib.genAttrs versions.names (
              name: pkgs.appendOverlays [
                overlays."cudaPackages${versions.versionSuffix name}"
                overlays.scaleBandaids
              ]
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
