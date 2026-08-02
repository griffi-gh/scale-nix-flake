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
    cp -RL --no-preserve=mode ${scale-unwrapped}/include $out/include

    # Give consumers link-time rpath to $out/lib
    mkdir -p $out/nix-support
    echo 'export NIX_LDFLAGS="''${NIX_LDFLAGS:-} -L${placeholder "out"}/lib -rpath ${placeholder "out"}/lib"' > $out/nix-support/setup-hook

    # https://github.com/spectral-compute/scale-validation/issues/62
    # HACK incoming:
    rm $out/include/redscale_impl/builtins.h
    sed -E \
      -e 's@__host__ __DEVICE float rsqrt\(float\);@__DEVICE float rsqrt(float);@' \
      -e 's@__host__ __DEVICE double rsqrt\(double\);@__DEVICE double rsqrt(double);@' \
      -e 's@__host__ __DEVICE float rsqrtf\(float\);@__DEVICE float rsqrtf(float);@' \
      -e 's@^([[:space:]]*(__host__)[[:space:]_A-Za-z]*\b(sinpi|cospi|tanpi|asinpi|acospi|atanpi|atan2pi)[fl]?[[:space:]]*\([^;]*\)[[:space:]]*;)@// \1@' \
      ${scale-unwrapped}/include/redscale_impl/builtins.h > $out/include/redscale_impl/builtins.h

    # HACK: https://code.spectralcompute.com/spectral-compute/scale/issues/1163
    patch -p1 -d $out < ${./patches/cublas-fix.patch}

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
