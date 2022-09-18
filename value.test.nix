{ pkgs ? import <nixpkgs> { }, nixt }:

let
  run = p: str:
    let result = p { buf = str; pos = 0; }; in
    if !result.isOk then null else
    result.v;

  matches = p: str: run p str == str;

  fails = p: str: run p str == null;
in

with import ./value.nix { lib = pkgs.lib; };

nixt.mkSuite "value" {
  "int" = run pInt "-1_2_3" == -123;
  "bool" = run pBool "true" == true;
}
