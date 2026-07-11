{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    systems.url = "github:nix-systems/default";
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = import inputs.systems;

      perSystem =
        { system, ... }:
        let
          pkgs = import inputs.nixpkgs {
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
          scaleVersionsAll =
            (pkgs.callPackage ./scalePackages/scaleVersions.nix { inherit mkScaleScope; }).scaleVersions;

          scalePackagesAll =
            (lib.mapAttrs' (
              name: scalePackages: lib.nameValuePair "scalePackages${nameSuffix name}" scalePackages
            ) scaleVersionsAll)
            // {
              inherit mkScaleScope;
            };
          overlayScalePackages = (final: prev: scalePackagesAll);

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
          overlayCudaPackagesFor =
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
          cudaOverlaysAll = lib.mapAttrs' (
            name: scalePackages:
            lib.nameValuePair "cudaPackages${nameSuffix name}" (overlayCudaPackagesFor scalePackages)
          ) scaleVersionsAll;

          nixpkgsScaleAll = lib.mapAttrs' (
            name: scalePackages:
            lib.nameValuePair "nixpkgsScale${nameSuffix name}" (
              import inputs.nixpkgs {
                inherit (pkgs) system config;
                overlays = [
                  overlayScalePackages
                  (overlayCudaPackagesFor scalePackages)
                ];
              }
            )
          ) scaleVersionsAll;
        in
        {

          legacyPackages = scalePackagesAll // nixpkgsScaleAll;

          overlays = {
            default = overlayScalePackages;
          }
          // cudaOverlaysAll;
        };
    };
}
