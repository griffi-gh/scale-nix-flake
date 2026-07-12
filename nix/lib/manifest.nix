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
      commitHash = "88b990553e79b7aaa2b4f225ae714e9cdca83ab1";
      commitDate = "2026.07.12";
    in
    {
      version = "0-unstable-${commitDate}";
      source = rec {
        _type = "requireFile";
        name = "scale-unstable-${commitDate}-Linux.tar.xz";
        url = "https://dev-artifacts.spectralcompute.com/external/nightlies/${commitHash}/linux/${name}";
        sha256 = "0c372l4vbcq8snvyym4wafj2xq321ldrw2jwfmg2kjzzqfnzh9kb";
      };
    };
}
