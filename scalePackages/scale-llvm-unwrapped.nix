{
  lib,
  stdenvNoCC,
  scale-unwrapped-nightly,
  scale-unwrapped ? scale-unwrapped-nightly,
  ...
}:
stdenvNoCC.mkDerivation {
  pname = "scale-llvm-unwrapped";
  inherit (scale-unwrapped) version;

  dontUnpack = true;
  dontBuild = true;

  installPhase = ''
    mkdir -p $out
    cp -Rs ${scale-unwrapped}/llvm/* $out
  '';

  meta = {
    description = "CUDA compiler driver (SCALE)";
    homepage = "https://scale-lang.com/";
    license = lib.licenses.unfree;
  };
}
