{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs =
    { nixpkgs, ... }:
    let
      system = "x86_64-linux";

      pkgs = import nixpkgs {
        inherit system;
        config = {
          allowUnfree = true;
          cudaSupport = true;
        };
      };
      inherit (pkgs) lib;

      nameDefault = "latest";
      nameSuffix = name: if name == nameDefault then "" else "_${name}";

      mkScaleScope = pkgs.callPackage ./scalePackages/mkScaleScope.nix { };
      scaleVersionsAll = pkgs.callPackage ./scalePackages/scaleVersions.nix { inherit mkScaleScope; };

      scalePackagesAll =
        (lib.mapAttrs' (
          name: scalePackages: lib.nameValuePair "scalePackages${nameSuffix name}" scalePackages
        ) scaleVersionsAll)
        // {
          inherit mkScaleScope;
        };
      overlayScalePackages = (final: prev: scalePackagesAll);

      cudaPackagesFor = scaleScope: {
        cuda_nvcc = scaleScope.scale-nvcc;
        cuda_cudart = scaleScope.scale-runtime;
        cuda_compat = scaleScope.scale-runtime; # HACK
        libcufft = scaleScope.scale-runtime;
        libcublas = scaleScope.scale-runtime;
        cuda_cccl = scaleScope.cccl;
      };
      overlayCudaPackagesFor =
        scaleScope:
        (
          final: prev:
          let
            cudaPackages = cudaPackagesFor scaleScope;
          in
          {
            scalePackages = scaleScope;
            cudaPackages = prev.cudaPackages.overrideScope (final: prev: cudaPackages);
          }
        );
      cudaOverlaysAll = lib.mapAttrs' (
        name: scalePackages:
        lib.nameValuePair "cudaPackages${nameSuffix name}" (overlayCudaPackagesFor scalePackages)
      ) scaleVersionsAll;

      nixpkgsScaleAll = lib.mapAttrs' (
        name: scalePackages:
        lib.nameValuePair "nixpkgsScale${nameSuffix name}" (
          import nixpkgs {
            inherit (pkgs) system config;
            overlays = [
              (overlayCudaPackagesFor scalePackages)
            ];
          }
        )
      ) scaleVersionsAll;
    in
    {
      legacyPackages.${system} = scalePackagesAll // nixpkgsScaleAll;

      overlays = {
        default = overlayScalePackages;
      }
      // cudaOverlaysAll;
    };
}
