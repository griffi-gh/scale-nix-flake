{
  lib,
  stdenvNoCC,
  cudaPackages,
  writeText,
  makeWrapper,
  scale-llvm,
  scale-runtime,
  target ? "gfx1103",
  nv_target ? "86",
  scaleVersion,
  scaleLicense,
  ...
}:
let
  inherit (cudaPackages) cudaMajorMinorVersion;

  ccmap = writeText "ccmap.conf" ''
    ${target} ${nv_target}
    ${target}
  '';

  setupScaleEnvHook = writeText "setup-scale-hook.sh" ''
    setupScaleEnv() {
      export CUDAARCHS="${nv_target}"
      export CMAKE_CUDA_ARCHITECTURES="${nv_target}"
      cmakeFlagsArray+=(
        "-DCUDAARCHS=${nv_target}"
        "-DCMAKE_CUDA_ARCHITECTURES=${nv_target}"
        "-DCUDA_VERSION=${cudaMajorMinorVersion}"
        "-DCUDA_VERSION_STRING=${cudaMajorMinorVersion}"
      )
    }
    preConfigureHooks+=(setupScaleEnv)
  '';

  nvccFlags = lib.escapeShellArgs [
    "--cuda-ccmap=${ccmap}"
    "--cuda-path=${scale-runtime}"
  ];
in
stdenvNoCC.mkDerivation {
  pname = "scale-nvcc";
  version = scaleVersion;

  __structuredAttrs = true;
  strictDeps = true;

  outputs = [ "out" ];
  dontUnpack = true;
  dontBuild = true;

  nativeBuildInputs = [
    cudaPackages.markForCudatoolkitRootHook
    makeWrapper
  ];
  propagatedBuildInputs = [
    cudaPackages.setupCudaHook
    setupScaleEnvHook
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/{bin,share/scale,nvvm/libdevice}

    cp ${scale-llvm}/bin/clang $out/bin/nvcc
    substituteInPlace $out/bin/nvcc \
      --replace-fail "${scale-llvm.cc}/bin/clang" "${scale-llvm.cc}/bin/nvcc" \
      --replace-warn "isCxx=0" "isCxx=1"

    wrapProgram $out/bin/nvcc \
      --add-flags "${nvccFlags}"

    ln -s ${ccmap} $out/share/scale/ccmap.conf
    ln -s ${scale-llvm.cc}/bin/amdgpu-arch $out/bin/amdgpu-arch
    ln -s ${scale-llvm.cc}/bin/lld $out/bin/device-linker-gnu
    ln -s ${scale-llvm.cc}/bin/lld $out/bin/lld
    ln -s ${scale-llvm.cc}/bin/ld.lld $out/bin/ld.lld
    ln -s ${scale-llvm}/bin/clang $out/bin/clang
    ln -s ${scale-llvm}/bin/clang++ $out/bin/clang++

    ln -s ${scale-runtime}/include $out/include
    ln -s ${scale-runtime}/lib $out/lib

    runHook postInstall
  '';

  meta = {
    description = "CUDA compiler driver (SCALE)";
    homepage = "https://scale-lang.com/";
    mainProgram = "nvcc";
    license = scaleLicense;
    sourceProvenance = with lib.sourceTypes; [
      binaryNativeCode
      fromSource
    ];
  };
}
