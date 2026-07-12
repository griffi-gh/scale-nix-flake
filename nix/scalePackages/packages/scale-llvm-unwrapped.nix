{
  lib,
  stdenvNoCC,
  scale-unwrapped,
  _scale,
  ...
}:
stdenvNoCC.mkDerivation {
  pname = "scale-llvm-unwrapped";
  inherit (_scale) version;

  dontUnpack = true;
  dontBuild = true;

  installPhase = ''
    mkdir -p $out
    cp -Rs ${scale-unwrapped}/llvm/* $out
  '';

  meta = {
    description = "CUDA compiler driver (SCALE)";
    homepage = "https://scale-lang.com/";
    inherit (_scale) license;
    sourceProvenance = with lib.sourceTypes; [
      binaryNativeCode
      fromSource
    ];
    platforms = [ "x86_64-linux" ];
  };
}
