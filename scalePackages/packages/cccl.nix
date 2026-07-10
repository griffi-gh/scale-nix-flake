{
  lib,
  stdenvNoCC,
  scale-unwrapped,
  ...
}:
stdenvNoCC.mkDerivation {
  pname = "cccl";
  version = "0-unstable-unsupported";

  __structuredAttrs = true;
  strictDeps = true;

  outputs = [ "out" ];

  dontUnpack = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp -Rs ${scale-unwrapped}/cccl/* $out
    ln -s $out/include/cccl $out/include

    runHook postInstall
  '';

  meta = {
    description = "Building blocks that make it easier to write safe and efficient CUDA C++ code";
    license = lib.licenses.asl20;
    sourceProvenance = with lib.sourceTypes; [
      fromSource
    ];
    platforms = lib.platforms.all;
  };
}
