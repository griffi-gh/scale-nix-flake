{
  mkScaleScope,
  requireFile,
  fetchurl,
}:
let
  scaleFreeLicense = import ./license/scaleFreeLicense.nix;
in
{
  scaleVersions = {
    latest =
      let
        version = "1.7.1";
        fileName = "scale-${version}-amd64.tar.xz";
      in
      mkScaleScope {
        version = version;
        src = fetchurl {
          name = fileName;
          inherit version;
          url = "https://pkgs.scale-lang.com/tar/${fileName}";
          hash = "sha256-Bgo2J3JfYABaaeIJszLXhH/XwD65UYvnBV3cADxzor4=";
        };
        license = scaleFreeLicense;
      };

    nightly =
      let
        commitHash = "49b59d463dd9a2f476b7144c3bf751c011309531";
        commitDate = "2026.07.03";
        name = "scale-unstable-${commitDate}-Linux.tar.xz";
        version = "0-unstable-${commitDate}";
      in
      mkScaleScope {
        inherit version;
        src = requireFile {
          inherit name;
          hash = "sha256-Fw7stE4e7BlUqftU6d0gzcTY/nvSiG+RT1u5truWZ7o=";
          url = "https://dev-artifacts.spectralcompute.com/external/nightlies/${commitHash}/linux/${name}";
        };
        license = scaleFreeLicense;
      };
  };
}
