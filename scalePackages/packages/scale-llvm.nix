{
  cudaPackages,
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
  gccForLibs = cudaPackages.backendStdenv.cc.cc;

  includeFortifyHeaders = false;

  extraBuildCommands = ''
    # kill hardening
    > $out/nix-support/add-hardening.sh

    # emulate leaky cstdlib header from CUDA
    echo "-include cstdlib" >> $out/nix-support/libcxx-cxxflags
  '';
}
