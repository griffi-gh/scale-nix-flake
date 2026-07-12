{ lib }:
let
  versions = import ../lib/versions.nix { inherit lib; };

  mkCudaOverlay = import ./mkCudaOverlay.nix;
  scalePackages = import ./scalePackages.nix;

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
  inherit scalePackages;
}
// cudaOverlays
