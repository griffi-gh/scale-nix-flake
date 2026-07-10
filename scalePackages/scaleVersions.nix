{
  mkScaleScope,
  requireFile,
  fetchurl,
}:
{
  scaleVersions = {
    latest =
      let
        version = "1.7.1";
        fileName = "scale-${version}-amd64.tar.xz";
      in
      mkScaleScope {
        scaleVersion = version;
        scaleSrc = fetchurl {
          name = fileName;
          inherit version;
          url = "https://pkgs.scale-lang.com/tar/${fileName}";
          hash = "sha256-Bgo2J3JfYABaaeIJszLXhH/XwD65UYvnBV3cADxzor4=";
        };
        scaleLicense = import ./license/scaleFreeLicense.nix;
      };

    nightly =
      let
        commitHash = "49b59d463dd9a2f476b7144c3bf751c011309531";
        commitDate = "2026.07.03";
        fileName = "scale-unstable-${commitDate}-Linux.tar.xz";
        version = "0-unstable-${commitDate}";
      in
      mkScaleScope {
        scaleVersion = version;
        scaleSrc = requireFile {
          name = fileName;
          hash = "sha256-Fw7stE4e7BlUqftU6d0gzcTY/nvSiG+RT1u5truWZ7o=";
          url = "https://dev-artifacts.spectralcompute.com/external/nightlies/${commitHash}/linux/${fileName}";
        };
        scaleLicense = import ./license/scaleFreeLicense.nix;
      };
  };
}
