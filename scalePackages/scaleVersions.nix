{
  mkScaleScope,
  requireFile,
  fetchurl,
}:
{
  latest =
    let
      version = "1.7.1";
    in
    mkScaleScope {
      scaleVersion = version;
      scaleSrc = fetchurl {
        inherit version;
        url = "https://pkgs.scale-lang.com/tar/scale-${version}-amd64.tar.xz";
        hash = "";
      };
    };

  nightly =
    let
      commitHash = "49b59d463dd9a2f476b7144c3bf751c011309531";
      commitDate = "2026.07.03";
      fileName = "scale-unstable-${commitDate}-Linux.tar.xz";
    in
    mkScaleScope {
      scaleVersion = "0-unstable-${commitDate}";
      scaleSrc = requireFile {
        name = fileName;
        hash = "sha256-Fw7stE4e7BlUqftU6d0gzcTY/nvSiG+RT1u5truWZ7o=";
        url = "https://dev-artifacts.spectralcompute.com/external/nightlies/${commitHash}/linux/${fileName}";
      };
    };
}
