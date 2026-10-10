{
  latest = rec {
    version = "1.7.4";
    source = let
      platform = "amd64";
    in rec {
      _type = "fetchurl";
      name = "scale-${version}-${platform}.tar.xz";
      url = "https://pkgs.scale-lang.com/tar/${name}";
      hash = "sha512-L3IlP9ZLb5VeNF+g4nOqxwobIJiaJiwqSmw8ABJ1lImuZd/g/6MsqQVOjUvU+jKfhsNvUpsoUXEXiTmGGtMxYQ==";
    };
  };

  # NB: downloading nightly artifacts currently requires vpn access or sso account
  nightly =
    let
      commitHash = "56034394355bba0d4aa932e3c387b35de90586f9";
      commitDate = "2026.10.10";
    in
    {
      version = "0-unstable-${commitDate}";
      source = rec {
        _type = "requireFile";
        name = "scale-unstable-${commitDate}-Linux.tar.xz";
        url = "https://dev-artifacts.spectralcompute.com/external/nightlies/${commitHash}/linux/${name}";
        hash = "sha512-Y9BGtpIvALBtwYK1db385oFDRegSeE0s1QpfM59yYtOE4je/J/2IIA1Z3m7JaQMbGupw3bvA+rPjsWJ9h3x4mA==";
      };
    };
}
