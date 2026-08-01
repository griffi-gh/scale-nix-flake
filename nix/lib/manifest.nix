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
      commitHash = "f5ce2c750670f010ecd12385f806c14641ab00a1";
      commitDate = "2026.08.01";
    in
    {
      version = "0-unstable-${commitDate}";
      source = rec {
        _type = "requireFile";
        name = "scale-unstable-${commitDate}-Linux.tar.xz";
        url = "https://dev-artifacts.spectralcompute.com/external/nightlies/${commitHash}/linux/${name}";
        sha256 = "17briwwzxbdws3pq22wpf4l76pqwm5i7ygsz63b47dsj6dds3l0d";
      };
    };
}
