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
      commitHash = "5f214ad8565c7d59aa54228df9ab9477dcbd8bd2";
      commitDate = "2026.11.20";
    in
    {
      version = "0-unstable-${commitDate}";
      source = rec {
        _type = "requireFile";
        name = "scale-unstable-${commitDate}-Linux.tar.xz";
        url = "https://dev-artifacts.spectralcompute.com/external/nightlies/${commitHash}/linux/${name}";
        hash = "sha512-eSAMso7HV01QhCjUdPIzThPlixfOdFop4rz8HH9GfjSK3BSIYLvquPaH3O9rolNgoG3fCRhLWtuprr27d2D1Ag==";
      };
    };
}
