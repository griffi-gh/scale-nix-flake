{
  lib,
  stdenvNoCC,
  cudaPackages,
  scale-unwrapped-nightly,
  scale-unwrapped ? scale-unwrapped-nightly,
  ...
}:
stdenvNoCC.mkDerivation {
  pname = "scale-runtime";
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

    mkdir -p $out/lib
    cp -Rs ${scale-unwrapped}/targets/amdgpu/lib/* $out/lib
    cp -Rs ${scale-unwrapped}/include $out/include
    ln -s $out/lib $out/lib64

    runHook postInstall
  '';

  meta = {
    description = "CUDA Runtime (SCALE)";
    homepage = "https://scale-lang.com/";
    license = lib.licenses.unfree;
  };
}
