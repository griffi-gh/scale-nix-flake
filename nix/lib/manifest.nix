{
  latest = rec {
    version = "1.7.3";
    source = let
      platform = if builtins.compareVersions version "1.7.3" >= 0 then "Linux" else "amd64";
    in rec {
      _type = "fetchurl";
      name = "scale-${version}-${platform}.tar.xz";
      url = "https://pkgs.scale-lang.com/tar/${name}";
      hash = "sha256-hpr7FeapR8eWbN+UCGM+q2OQsh3a43VVOOujEnxocdo=";
    };
  };

  # NB: downloading nightly artifacts currently requires vpn access or sso account
  nightly =
    let
      commitHash = "19908a3fa89c09ed5a7900aa1408e0cc8d37845f";
      commitDate = "2026.09.27";
    in
    {
      version = "0-unstable-${commitDate}";
      source = rec {
        _type = "requireFile";
        name = "scale-unstable-${commitDate}-Linux.tar.xz";
        url = "https://dev-artifacts.spectralcompute.com/external/nightlies/${commitHash}/linux/${name}";
        sha256 = "09xkli8417357r9i86q2686wqjiqm4yyz468z0nbpf4qhf3db729";
      };
    };
}
