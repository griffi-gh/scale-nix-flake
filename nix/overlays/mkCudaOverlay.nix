scaleScope: final: prev: {
  # TODO overlays for other CUDA versions (e.g. cudaPackages_13 etc)
  cudaPackages = prev.cudaPackages.overrideScope (
    cf: cp: {
      # the main one :3
      cuda_nvcc = scaleScope.scale-nvcc;

      # legacy combined toolkit
      # (hack: our scale-nvcc already merges in libs/includes from scale-runtime so this just works)
      cudatoolkit = scaleScope.scale-nvcc;

      # (HACK: we have all of the libs in single scale-runtime derivation rn)
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

      # cccl: override both legacy and the new alias
      cuda_cccl = scaleScope.cccl;
      cccl = scaleScope.cccl;
    }
  );
}
