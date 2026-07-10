# SCALE Nix Flake

Nix flake for the [SCALE](https://scale-lang.com/) CUDA-compatible compiler toolkit.

Can be used as a drop-in overlay for compiling any existing
packages that depend on `cudaPackages`!

## Outputs

* `legacyPackages.x86_64-linux`:
  * `scalePackages` / `scalePackages_nightly`: Standalone SCALE toolchain
    (`scale-nvcc`, `scale-runtime`, etc...).
  * `nixpkgsScale` / `nixpkgsScale_nightly`: Full Nixpkgs instances with
    `cudaPackages` globally replaced by their respective SCALE packages.\
    (use `overlays.cudaPackages` overlays over this whenever possible)
* `overlays`:
  * `default`: Adds the SCALE packages to `pkgs`.
  * `cudaPackages` / `cudaPackages_nightly`: Overrides `cudaPackages` to use SCALE.

scalePackages currently includes:

* `scale-unwrapped` - The raw patched SCALE tarball tree
* `scale-runtime` - SCALE CUDA runtime libraries and includes
* `scale-llvm-unwrapped` - SCALE LLVM compiler binaries (unwrapped)
* `scale-llvm` - Scale LLVM compiler wrapped with nixpkg's `wrapCC`
* `scale-nvcc` - The main SCALE NVCC compiler package
