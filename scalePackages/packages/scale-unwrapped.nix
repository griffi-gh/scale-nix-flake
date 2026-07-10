{
  lib,
  stdenv,
  autoPatchelfHook,
  zlib,
  zstd,
  numactl,
  elfutils,
  libdrm,
  _scale,
  ...
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "scale-unwrapped";

  inherit (_scale) version src;

  nativeBuildInputs = [
    autoPatchelfHook
  ];
  buildInputs = [
    (lib.getLib stdenv.cc.cc)
    zlib
    zstd
    numactl
    elfutils
    libdrm
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p "$out"
    cp -r ./* "$out"

    # XXX: symlinking to real gcc breaks nix build support
    # so just remove it altgether
    for target in $out/targets/*; do
      rm $target/bin/gcc
      rm $target/bin/g++
    done

    runHook postInstall
  '';

  meta = {
    description = "CUDA-compatible GPU programming toolkit";
    homepage = "https://scale-lang.com/";
    inherit (_scale) license;
    sourceProvenance = with lib.sourceTypes; [
      binaryNativeCode
      binaryBytecode
      fromSource
    ];
    platforms = [ "x86_64-linux" ];
  };
})
