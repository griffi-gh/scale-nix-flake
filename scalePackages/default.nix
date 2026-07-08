{ lib, newScope, callPackage }:
lib.makeScope newScope (self: {
  scale-unwrapped-nightly = callPackage ./scale-unwrapped-nightly.nix self;
  scale-llvm-unwrapped = callPackage ./scale-llvm-unwrapped.nix self;
  scale-llvm = callPackage ./scale-llvm.nix self;
  scale-nvcc = callPackage ./scale-nvcc.nix self;
  scale-runtime = callPackage ./scale-runtime.nix self;
  scale-cccl = callPackage ./scale-cccl.nix self;
})
