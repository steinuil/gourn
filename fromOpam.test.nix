{ pkgs ? import <nixpkgs> { }, nixt }:

let
  p = import ./fromOpam.nix { lib = pkgs.lib; };

  run = p: str:
    let result = p { buf = str; pos = 0; }; in
    if !result.isOk then null else
    builtins.substring result.v.start result.v.len str;
  
  matches = p: str: run p str == str;
  
  fails = p: str: run p str == null;
in

nixt.mkSuites {
  "ident" = {
    "alpha" = matches p.pIdent "abcd";
    "no alpha" = fails p.pIdent "123__";
    "alphanumeric" = matches p.pIdent "a123";
    "underscores" = matches p.pIdent "a__";
    "starts with a number" = matches p.pIdent "123a";
    "starts with an underscore" = matches p.pIdent "__a";
    "all characters" = matches p.pIdent "__124a5_agFA";
    "plus" = matches p.pIdent "__2432asf+235ggw+12fa214__";
    "plus and colon" = matches p.pIdent "42ggsf+3gg+352gret:34aaf";
    "colon before plus" = run p.pIdent "asd:asd+asd" == "asd:asd";
    "invalid plus" = run p.pIdent "asd+123" == "asd";
    "invalid colon" = run p.pIdent "asd:123" == "asd";
    "single underscore" = matches p.pIdent "_+_+_";
    "underscore" = run p.pIdent "__123" == "_";
    "underscore after colon" = run p.pIdent "_:_" == "_";
  };
}
