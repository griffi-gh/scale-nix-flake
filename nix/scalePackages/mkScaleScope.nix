{ lib, ... }:
{
  perSystem =
    { pkgs, ... }:
    let
      inherit (pkgs) newScope callPackage;
    in
    {
      _module.args.mkScaleScope =
        _scale@{
          version,
          src,
          license,
        }:
        lib.makeScope newScope (
          self:
          let
            scope = self // {
              inherit _scale;
            };
          in
          {
            scale-unwrapped = callPackage ./packages/scale-unwrapped.nix scope;
            scale-llvm-unwrapped = callPackage ./packages/scale-llvm-unwrapped.nix scope;
            scale-llvm = callPackage ./packages/scale-llvm.nix scope;
            scale-nvcc = callPackage ./packages/scale-nvcc.nix scope;
            scale-runtime = callPackage ./packages/scale-runtime.nix scope;
            cccl = callPackage ./packages/cccl.nix scope;
          }
        );
    };

}
