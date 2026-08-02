scaleScope: final: prev:
let
  inherit (prev) lib;

  mkOverrideCudaScope =
    cudaScope:
    let
      nvccPackage = scaleScope.scale-nvcc.override { cudaPackages = cudaScope; };
    in
    cudaScope.overrideScope (
      cudaFinal: cudaPrev: {
        # the main one :3
        cuda_nvcc = nvccPackage;
        # legacy combined toolkit
        # (hack: scale-nvcc already merges libs/includes from scale-runtime, so this just works)
        cudatoolkit = nvccPackage;

        # HACK: all libs currently live in a single scale-runtime derivation.
        cuda_cudart = scaleScope.scale-runtime;
        cuda_compat = scaleScope.scale-runtime;
        cuda_nvrtc = scaleScope.scale-runtime;
        libcufft = scaleScope.scale-runtime;
        libcublas = scaleScope.scale-runtime;
        libcurand = scaleScope.scale-runtime;
        libcusolver = scaleScope.scale-runtime;
        libcusparse = scaleScope.scale-runtime;
        libcusparse_lt = scaleScope.scale-runtime;
        libnvjitlink = scaleScope.scale-runtime;
        cudnn = scaleScope.scale-runtime;

        # cccl: override both the legacy name and the new alias
        cuda_cccl = scaleScope.cccl;
        cccl = scaleScope.cccl;

        # TODO: set flags.cudaCapabilities to match (SCALE) cuda_nvcc.nv_target
        # (keep in mind the format, aka 86 -> "8.6")
      }
    );
in
lib.mapAttrs (_: mkOverrideCudaScope) (
  lib.filterAttrs (name: _: name == "cudaPackages" || lib.hasPrefix "cudaPackages_" name) prev
)
