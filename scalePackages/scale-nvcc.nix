{
  lib,
  stdenvNoCC,
  cudaPackages,
  writeText,
  scale-llvm,
  scale-runtime,
  target ? "gfx1103",
  nv_target ? "86",
  ...
}:
let
  ccmap = writeText "ccmap.conf" ''
    ${target} ${nv_target}
    ${target}
  '';
in
stdenvNoCC.mkDerivation {
  pname = "scale-nvcc";
  version = "0-unstable";

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

    mkdir -p $out/{lib,bin,libexec,share/scale,nvvm/libdevice}
    ln -s ${scale-llvm}/bin/clang $out/bin/nvcc
    ln -s ${scale-llvm}/bin/clang $out/bin/clang
    ln -s ${scale-llvm}/bin/clang $out/bin/clang++
    ln -s ${scale-llvm.cc}/bin/amdgpu-arch $out/bin/amdgpu-arch
    ln -s ${scale-llvm.cc}/bin/lld $out/bin/device-linker-gnu
    ln -s ${scale-llvm.cc}/bin/lld $out/bin/lld
    ln -s ${scale-llvm.cc}/bin/lld $out/bin/ld.lld
    cp -Rs ${scale-llvm.cc}/lib/* $out/lib
    cp -Rs ${scale-llvm.cc}/libexec/* $out/libexec
    ln -s ${ccmap} $out/share/scale/ccmap.conf

    runHook postInstall
  '';

  meta = {
    description = "CUDA compiler driver (SCALE)";
    homepage = "https://scale-lang.com/";
    mainProgram = "nvcc";
    license = lib.licenses.unfree;
  };
}
