
# SCALE Nix Flake

<img src=".assets/logo1.png" alt="Spectral Compute logo" float="left" align="left" width="100" height="100" />

Nix flake for the [SCALE](https://scale-lang.com/) CUDA-compatible compiler toolkit
(by Spectral Compute).

Can be used as a drop-in overlay for compiling any existing
packages that depend on `cudaPackages`!

## Outputs

Packages (`legacyPackages.<system>.*`):

- `scalePackages`, `scalePackages_nightly`: Standalone SCALE toolchain.
  - `cccl` - version of CCCL shipped with the SCALE tarball
  - `scale-unwrapped` - The raw patched SCALE tarball tree
  - `scale-runtime` - SCALE CUDA runtime libraries and includes
  - `scale-llvm-unwrapped` - SCALE LLVM compiler binaries (unwrapped)
  - `scale-llvm` - Scale LLVM compiler wrapped with nixpkg's `wrapCC`
  - `scale-nvcc` - The main SCALE NVCC compiler package
- `nixpkgsScale`, `nixpkgsScale_nightly`: Full Nixpkgs instances with
  `cudaPackages` globally replaced by their respective SCALE packages.
  - This is soft-deprecated/only used for development purposes:
    use `overlays.cudaPackages` overlays over this whenever possible)

Overlays (`overlays.*`):

- `overlays`:
  - `default`: Adds the SCALE packages to `pkgs`.
  - `cudaPackages`, `cudaPackages_nightly`: Overrides `cudaPackages` to use SCALE.
