{
  lib,
  stdenv,
  requireFile,
  autoPatchelfHook,
  zlib,
  zstd,
  numactl,
  elfutils,
  libdrm,
  gcc,
  ...
}:
let
  commitHash = "49b59d463dd9a2f476b7144c3bf751c011309531";
  commitDate = "2026.07.03";
  fileName = "scale-unstable-${commitDate}-Linux.tar.xz";
in
stdenv.mkDerivation (finalAttrs: {
  pname = "scale-unwrapped-nightly";
  version = "0-unstable-${commitDate}-${commitHash}";

  src = requireFile {
    name = fileName;
    hash = "sha256-Fw7stE4e7BlUqftU6d0gzcTY/nvSiG+RT1u5truWZ7o=";
    url = "https://dev-artifacts.spectralcompute.com/external/nightlies/${commitHash}/linux/${fileName}";
  };

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
    description = "CUDA-compatible GPU programming toolkit (nightly)";
    homepage = "https://scale-lang.com/";
    license = lib.licenses.unfree;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
})
