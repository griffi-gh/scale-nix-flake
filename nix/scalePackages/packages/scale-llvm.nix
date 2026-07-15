{
  wrapCCWith,
  cudaPackages,
  scale-llvm-unwrapped,
  ...
}:
wrapCCWith {
  name = "scale-llvm";

  cc = scale-llvm-unwrapped;
  inherit (cudaPackages.backendStdenv.cc) bintools libc;

  isClang = true;
  useCcForLibs = true;
  gccForLibs = cudaPackages.backendStdenv.cc.cc;

  includeFortifyHeaders = false;

  extraBuildCommands = ''
    # kill hardening
    > $out/nix-support/add-hardening.sh

    # HACK: emulate leaky cstdlib header from CUDA
    echo "-include cstdlib" >> $out/nix-support/libcxx-cxxflags
  '';
}
