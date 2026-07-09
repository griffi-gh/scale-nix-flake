{
  lib,
  stdenvNoCC,
  scale-unwrapped-nightly,
  scale-unwrapped ? scale-unwrapped-nightly,
  ...
}:
stdenvNoCC.mkDerivation {
  pname = "cccl";
  inherit (scale-unwrapped) version;

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
