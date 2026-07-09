{
  cudaPackages,
  bintools,
  wrapCCWith,
  scale-llvm-unwrapped,
  scale-runtime,
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

  extraBuildCommands = ''
    # ensure that scale-runtime headers and redscale_impl/wrappers are always searched before cstdlib
    flags="$(< $out/nix-support/libcxx-cxxflags)"
    echo "-isystem ${scale-runtime}/include -isystem ${scale-runtime}/include/redscale_impl/wrappers $flags -include cstdlib" > $out/nix-support/libcxx-cxxflags

    # kill hardening
    > $out/nix-support/add-hardening.sh
  '';
}
