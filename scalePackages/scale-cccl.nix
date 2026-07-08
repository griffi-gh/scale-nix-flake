{
  lib,
  stdenvNoCC,
  cudaPackages,
  scale-unwrapped-nightly,
  scale-unwrapped ? scale-unwrapped-nightly,
  ...
}:
stdenvNoCC.mkDerivation {
  pname = "scale-cccl";
  inherit (scale-unwrapped) version;

  __structuredAttrs = true;
  strictDeps = true;

  outputs = [ "out" ];

  dontUnpack = true;
  dontBuild = true;

  nativeBuildInputs = [
    cudaPackages.markForCudatoolkitRootHook
  ];
  propagatedBuildInputs = [
    cudaPackages.setupCudaHook
  ];
  propagatedBuildOutputs = [
    "bin"
    "include"
    "lib"
    "stubs"
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp -Rs ${scale-unwrapped}/cccl/* $out
    ln -s $out/include/cccl $out/include

    runHook postInstall
  '';

  meta = {
    description = "Building blocks that make it easier to write safe and efficient CUDA C++ code (SCALE)";
    homepage = "https://scale-lang.com/";
    license = lib.licenses.unfree;
  };
}
