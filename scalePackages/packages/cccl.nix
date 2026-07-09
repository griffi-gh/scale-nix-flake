{
  lib,
  stdenvNoCC,
  scale-unwrapped,
  scaleVersion,
  ...
}:
stdenvNoCC.mkDerivation {
  pname = "cccl";
  version = scaleVersion;

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
    license = lib.licenses.unfree;
  };
}
