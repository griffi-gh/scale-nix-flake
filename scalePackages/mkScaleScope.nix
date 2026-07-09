{
  lib,
  newScope,
  callPackage,
  ...
}:
meta@{
  scaleVersion,
  scaleSrc,
}:
lib.makeScope newScope (
  self:
  let
    scope = self // meta;
  in
  {
    scale-unwrapped = callPackage ./packages/scale-unwrapped.nix scope;
    scale-llvm-unwrapped = callPackage ./packages/scale-llvm-unwrapped.nix scope;
    scale-llvm = callPackage ./packages/scale-llvm.nix scope;
    scale-nvcc = callPackage ./packages/scale-nvcc.nix scope;
    scale-runtime = callPackage ./packages/scale-runtime.nix scope;
    cccl = callPackage ./packages/cccl.nix scope;
  }
)
