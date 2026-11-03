{
  latest = rec {
    version = "1.7.5";
    source = let
      platform = "amd64";
    in rec {
      _type = "fetchurl";
      name = "scale-${version}-${platform}.tar.xz";
      url = "https://pkgs.scale-lang.com/tar/${name}";
      hash = "sha512-/MstVcc8+oPW2bCgSEhdVL1mxJAKl/VFECG6CyKgAPisIV0/edhMqQ7+o9KQ48DvKkw/ZzN7lFs+dDeAXcx7gw==";
    };
  };

  # NB: downloading nightly artifacts currently requires vpn access or sso account
  nightly =
    let
      commitHash = "f64a3ba4e2b781488bf7053ea6463c3d4ec35aec";
      commitDate = "2026.11.03";
    in
    {
      version = "0-unstable-${commitDate}";
      source = rec {
        _type = "requireFile";
        name = "scale-unstable-${commitDate}-Linux.tar.xz";
        url = "https://dev-artifacts.spectralcompute.com/external/nightlies/${commitHash}/linux/${name}";
        hash = "sha512-Q0PQHzA+QETSdBOVFkSTxIh4M3tBuc4/hrDPOuWs781aRvBi8Qt//AkdvN1LQPFA8CJAZ29JSJ1LJ6hlNr/3HA==";
      };
    };
}
