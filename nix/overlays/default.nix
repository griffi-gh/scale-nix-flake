{ lib }:
let
  versions = import ../lib/versions.nix { inherit lib; };

  scalePackages = import ./scalePackages.nix;
  mkCudaOverlay = import ./mkCudaOverlay.nix;
  scaleBandaids = import ./scaleBandaids.nix;

  mkCudaOverlayFor =
    name:
    lib.composeExtensions scalePackages (
      final: prev: mkCudaOverlay final.scaleVersions.${name} final prev
    );
  cudaOverlays = versions.flattenVersions "cudaPackages" (
    lib.genAttrs versions.names mkCudaOverlayFor
  );
in
{
  inherit scaleBandaids;
  inherit scalePackages;
}
// cudaOverlays
