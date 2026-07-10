{
  lib,
  stdenvNoCC,
  scale-unwrapped,
  scaleVersion,
  scaleLicense,
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
    license = scaleLicense;
    sourceProvenance = with lib.sourceTypes; [
      binaryNativeCode
      fromSource
    ];
  };
}
