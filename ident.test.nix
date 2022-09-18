{ pkgs ? import <nixpkgs> { }, nixt }:

let
  run = p: str:
    let result = p { buf = str; pos = 0; }; in
    if !result.isOk then null else
    builtins.substring result.v.start result.v.len str;

  matches = p: str: run p str == str;

  fails = p: str: run p str == null;
in

with import ./ident.nix { lib = pkgs.lib; };

nixt.mkSuite "ident" {
  "alpha" = matches pIdent "abcd";
  "no alpha" = fails pIdent "123__";
  "alphanumeric" = matches pIdent "a123";
  "underscores" = matches pIdent "a__";
  "starts with a number" = matches pIdent "123a";
  "starts with an underscore" = matches pIdent "__a";
  "all characters" = matches pIdent "__124a5_agFA";
  "plus" = matches pIdent "__2432asf+235ggw+12fa214__";
  "plus and colon" = matches pIdent "42ggsf+3gg+352gret:34aaf";
  "colon before plus" = run pIdent "asd:asd+asd" == "asd:asd";
  "invalid plus" = run pIdent "asd+123" == "asd";
  "invalid colon" = run pIdent "asd:123" == "asd";
  "single underscore" = matches pIdent "_+_+_";
  "underscore" = run pIdent "__123" == "_";
  "underscore after colon" = run pIdent "_:_" == "_";
}
