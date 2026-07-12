{
  lib,
  nameSuffix,
  ...
}:
let
  cudaPackagesFor =
    scaleScope: with scaleScope; {
      # the main one :3
      cuda_nvcc = scale-nvcc;

      # (HACK: we have all of the libs in single scale-runtime derivation rn)
      cuda_cudart = scale-runtime;
      cuda_compat = scale-runtime;
      libcufft = scale-runtime;
      libcublas = scale-runtime;
      libcurand = scale-runtime;
      libcusolver = scale-runtime;
      libcusparse = scale-runtime;
      libcusparse_lt = scale-runtime;
      cudnn = scale-runtime;

      # override both legacy and the new alias
      cuda_cccl = scaleScope.cccl;
      cccl = scaleScope.cccl;
    };

  cudaPackagesOverlayFor =
    scaleScope:
    (
      final: prev:
      let
        cudaPackages = cudaPackagesFor scaleScope;
      in
      {
        # TODO overlays for other CUDA versions (e.g. cudaPackages_13 etc)
        cudaPackages = prev.cudaPackages.overrideScope (final: prev: cudaPackages);
      }
    );
in
{
  _module.args = {
    inherit cudaPackagesFor cudaPackagesOverlayFor;
  };

  perSystem =
    { scaleVersions, ... }:
    {
      overlays = lib.mapAttrs' (
        name: scalePackages:
        lib.nameValuePair "cudaPackages${nameSuffix name}" (cudaPackagesOverlayFor scalePackages)
      ) scaleVersions;
    };
}
