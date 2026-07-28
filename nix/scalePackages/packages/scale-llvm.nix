{
  wrapCCWith,
  cudaPackages,
  scale-runtime,
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

  extraBuildCommands = let
    preincludeHack = builtins.toFile "nix-preinclude.h" ''
      // HACK: emulate leaky cstdlib header from CUDA
      #if defined(__cplusplus)
        #include <cstdlib>
      #endif
    '';
  in ''
    # kill hardening
    > $out/nix-support/add-hardening.sh

    # HACK: ensure redscale wrappers are searched before cstdlib;
    # also, include our preinclude hack
    flags="$(< $out/nix-support/libcxx-cxxflags)"
    echo "-isystem ${scale-runtime}/include -isystem ${scale-runtime}/include/redscale_impl/wrappers $flags -include ${preincludeHack}" > $out/nix-support/libcxx-cxxflags
  '';
}
