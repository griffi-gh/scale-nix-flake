{
  latest = rec {
    version = "1.7.1";
    source = rec {
      _type = "fetchurl";
      name = "scale-${version}-amd64.tar.xz";
      url = "https://pkgs.scale-lang.com/tar/${name}";
      hash = "sha256-Bgo2J3JfYABaaeIJszLXhH/XwD65UYvnBV3cADxzor4=";
    };
  };

  # NB: downloading nightly artifacts currently requires vpn access or sso account
  nightly =
    let
      commitHash = "c190f2dbd2ba1492b7263209319f5e279173b559";
      commitDate = "2026.07.28";
    in
    {
      version = "0-unstable-${commitDate}";
      source = rec {
        _type = "requireFile";
        name = "scale-unstable-${commitDate}-Linux.tar.xz";
        url = "https://dev-artifacts.spectralcompute.com/external/nightlies/${commitHash}/linux/${name}";
        sha256 = "1ppbzmvh788swlq73df386ni52zngah1bka95abzf04r58naprfh";
      };
    };
}
