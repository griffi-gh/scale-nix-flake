{
  lib,
  stdenvNoCC,
  cudaPackages,
  writeText,
  makeWrapper,
  makeSetupHook,
  scale-llvm,
  scale-runtime,
  target ? "gfx1103",
  nv_target ? "86",
  _scale,
  ...
}:
let
  inherit (cudaPackages) cudaMajorMinorVersion cudaMajorMinorPatchVersion;

  ccmap = writeText "ccmap.conf" ''
    ${target} ${nv_target}
    ${target}
  '';

  setupScaleEnvHook = makeSetupHook {
    name = "setup-scale-hook";
  } (writeText "setup-scale-hook.sh" ''
    export CUDAARCHS="${nv_target}"

    # CMake setup
    export CMAKE_CUDA_ARCHITECTURES="${nv_target}"
    appendToVar cmakeFlags "-DCUDAARCHS=${nv_target}"
    appendToVar cmakeFlags "-DCMAKE_CUDA_ARCHITECTURES=${nv_target}"
    appendToVar cmakeFlags "-DCUDA_VERSION=${cudaMajorMinorVersion}"
    appendToVar cmakeFlags "-DCUDA_VERSION_STRING=${cudaMajorMinorVersion}"

    # HACK: https://code.spectralcompute.com/spectral-compute/scale/issues/1166
    # (projects based on cudarc cannot disover CUDA version with SCALE)
    export CUDARC_CUDA_VERSION="${lib.replaceString "." "0" cudaMajorMinorVersion}0"
  '');

  extraNvccFlags = lib.escapeShellArgs [
    "--cuda-ccmap=${ccmap}"
    "--cuda-path=${scale-runtime}"
  ];
in
stdenvNoCC.mkDerivation {
  pname = "scale-nvcc";
  inherit (_scale) version;

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

    # HACK 1:
    # basically we create a new wrapper of the *unwrapped* nvcc (.nvcc-argv0), overriding it's target argv0 to $out/bin/nvcc
    # then, we copy the wrapCC wrapped version of nvcc ($out/bin/nvcc), and override its target unwrapped executable path to actaully
    # point to the in .nvcc-argv0 our directory, instead of the original unwrapped clang
    # This fixes InstalledDir/version.txt resolution to actually point to the wrapped derivation;
    # (This solution is ceirtanly not ideal buuuuuut should be good enough i guess....)
    makeWrapper "${scale-llvm.cc}/bin/nvcc" $out/bin/.nvcc-argv0 \
      --argv0 "$out/bin/nvcc";
    cp ${scale-llvm}/bin/clang $out/bin/nvcc
    substituteInPlace $out/bin/nvcc \
      --replace-fail "${scale-llvm.cc}/bin/clang" "$out/bin/.nvcc-argv0" \
      --replace-warn "isCxx=0" "isCxx=1"

    # HACK 2:
    # we need to add some extra stuff, but can't edit the existing wrapper....
    # so here, we wrap the wrapper :p
    # (POP QUIZ: how many layers of wrappers does an `nvcc` call go through in this setup)
    wrapProgram $out/bin/nvcc \
      --add-flags "${extraNvccFlags}" \
      --set SCALE_CUDA_VERSION "${cudaMajorMinorVersion}"

    ln -s ${ccmap} $out/share/scale/ccmap.conf
    ln -s ${scale-llvm.cc}/bin/amdgpu-arch $out/bin/amdgpu-arch
    ln -s ${scale-llvm.cc}/bin/lld $out/bin/device-linker-gnu
    ln -s ${scale-llvm.cc}/bin/lld $out/bin/lld
    ln -s ${scale-llvm.cc}/bin/ld.lld $out/bin/ld.lld
    ln -s ${scale-llvm}/bin/clang $out/bin/clang
    ln -s ${scale-llvm}/bin/clang++ $out/bin/clang++

    ln -s ${scale-runtime}/include $out/include
    ln -s ${scale-runtime}/lib $out/lib

    # HACK: needed for the "Cuda compilation tools..." line in "nvcc --version" to actually make sense
    # (SCALE_CUDA_VERSION doesnt seem to actually work in nvcc mode??? either way good to have)
    echo "CUDA Version ${cudaMajorMinorPatchVersion} (Actually, no. This is the SCALE compiler; version v${_scale.version})" > $out/version.txt

    runHook postInstall
  '';

  meta = {
    description = "CUDA compiler driver (SCALE)";
    homepage = "https://scale-lang.com/";
    mainProgram = "nvcc";
    inherit (_scale) license;
    sourceProvenance = with lib.sourceTypes; [
      binaryNativeCode
      fromSource
    ];
    platforms = [ "x86_64-linux" ];
  };
}
