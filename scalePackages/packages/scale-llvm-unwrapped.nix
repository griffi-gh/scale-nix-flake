{
  lib,
  stdenvNoCC,
  scale-unwrapped,
  scaleVersion,
  ...
}:
stdenvNoCC.mkDerivation {
  pname = "scale-llvm-unwrapped";
  version = scaleVersion;

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
