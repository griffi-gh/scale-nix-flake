# fixes packages that currently don't compile w/SCALE due to missing features
final: prev:
(
  {
    onnxruntime = prev.onnxruntime.override {
      cudaSupport = false; # requires cudnn, not supported
      ncclSupport = false; # nccl does not build under SCALE
    };
  }
  // (
    let
      cudaOverridesFor =
        scope:
        scope.overrideScope (
          cudaFinal: cudaPrev: {
            # HACK: this prevents some third party stuff from relying on nccl, which is currently broken under SCALE
            nccl = cudaPrev.nccl.overrideAttrs (old: {
              meta = old.meta // {
                available = false;
              };
            });
          }
        );

      cudaPackagesAll = lib.filterAttrs (
        name: _: name == "cudaPackages" || lib.hasPrefix "cudaPackages_" name
      ) prev;
    in
    (lib.mapAttrs (_: cudaOverridesFor) cudaPackagesAll)
  )
)
