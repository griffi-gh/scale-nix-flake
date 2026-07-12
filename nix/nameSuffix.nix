{ ... }:
let
  nameDefault = "latest";
  nameSuffix = name: if name == nameDefault then "" else "_${name}";
in
{
  _module.args = { inherit nameDefault nameSuffix; };
}
