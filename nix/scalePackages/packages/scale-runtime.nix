{
  lib,
  stdenvNoCC,
  cudaPackages,
  scale-unwrapped,
  _scale,
  ...
}:
let
  isNightly = (lib.versions.major _scale.version) == "0";
in
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
