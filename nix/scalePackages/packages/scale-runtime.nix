{
  lib,
  stdenvNoCC,
  cudaPackages,
  scale-unwrapped,
  _scale,
  ...
}:
stdenvNoCC.mkDerivation {
  pname = "scale-runtime";
  inherit (_scale) version;

  outputs = [ "out" ];

  __structuredAttrs = true;
  strictDeps = true;

  dontUnpack = true;
  dontBuild = true;

  nativeBuildInputs = [
    cudaPackages.markForCudatoolkitRootHook
  ];
  propagatedBuildInputs = [
    cudaPackages.setupCudaHook
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib
    ln -s $out/lib $out/lib64
    cp -Rs --no-preserve=mode ${scale-unwrapped}/targets/amdgpu/lib/* $out/lib
    cp -Rs --no-preserve=mode ${scale-unwrapped}/include $out/include

    # https://github.com/spectral-compute/scale-validation/issues/62
    rm $out/include/redscale_impl/builtins.h
    sed -e 's/__host__ __DEVICE float rsqrt(float);/\/\/ __host__ __DEVICE float rsqrt(float);/' \
        -e 's/__host__ __DEVICE double rsqrt(double);/\/\/ __host__ __DEVICE double rsqrt(double);/' \
        -e 's/__host__ __DEVICE float rsqrtf(float);/\/\/ __host__ __DEVICE float rsqrtf(float);/' \
        ${scale-unwrapped}/include/redscale_impl/builtins.h > $out/include/redscale_impl/builtins.h

    runHook postInstall
  '';

  meta = {
    description = "CUDA Runtime (SCALE)";
    homepage = "https://scale-lang.com/";
    inherit (_scale) license;
    sourceProvenance = with lib.sourceTypes; [
      binaryNativeCode
      binaryBytecode
      fromSource
    ];
    platforms = [ "x86_64-linux" ];
  };
}
