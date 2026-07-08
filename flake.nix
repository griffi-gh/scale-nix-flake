{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs = { self, nixpkgs }: let
    system = "x86_64-linux";

    pkgs = import nixpkgs {
      inherit system;
      config = {
        allowUnfree = true;
        cudaSupport = true;
      };
    };

    scalePackages = pkgs.callPackage ./scalePackages {};
    cudaPackages = {
      cuda_nvcc = scalePackages.scale-nvcc;
      cuda_cudart = scalePackages.scale-runtime;
      cuda_compat = scalePackages.scale-runtime; # HACK
      libcufft = scalePackages.scale-runtime;
      libcublas = scalePackages.scale-runtime;
      cuda_cccl = scalePackages.scale-cccl;
      # autoAddCudaCompatRunpath = ... enableHook = false;
    };

    overlayScalePackages = (final: prev: {
      inherit scalePackages;
    });
    overlayCudaPackages = (final: prev: {
      inherit scalePackages;
      cudaPackages = prev.cudaPackages.overrideScope (final: prev: cudaPackages);
    });

    nixpkgs-scale = import nixpkgs {
      inherit system;
      config = {
        allowUnfree = true;
        cudaSupport = true;
      };
      overlays = [
        overlayScalePackages
        overlayCudaPackages
      ];
    };
  in {
    packages.x86_64-linux = scalePackages;

    legacyPackages.x86_64-linux = {
      inherit scalePackages cudaPackages nixpkgs-scale;
    };

    overlays = {
      scalePackages = overlayScalePackages;
      cudaPackages = overlayCudaPackages;
    };
  };
}
