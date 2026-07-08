{
  lib,
  llvmPackages,
  gcc,
  bintools,
  wrapCCWith,
  scale-llvm-unwrapped,
  ...
}:
wrapCCWith {
  name = "scale-llvm";

  cc = scale-llvm-unwrapped;
  inherit bintools;
  inherit (bintools) libc;

  isClang = true;
  useCcForLibs = true;
  gccForLibs = gcc.cc;
}
