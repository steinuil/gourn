{ pkgs ? import <nixpkgs> { }, nixt }:

let
  run = p: str:
    let result = p { buf = str; pos = 0; }; in
    if !result.isOk then null else
    result.v;

  matches = p: str: run p str == str;

  fails = p: str: run p str == null;
in

with import ./string.nix { lib = pkgs.lib; };

nixt.mkSuite "string" {
  "empty" = run pOpamStringSingle "\"\"" == "";
  "stuff in the string" = run pOpamStringSingle "\"abcd\"" == "abcd";
  "escaped stuff in the string" =
    run pOpamStringSingle "\"a\\\\b\"" == "a\\b";
  "only escape codes" =
    run pOpamStringSingle "\"\\n\\r\\'\\\"\\t\\b\\ \"" == "\n\r'\"\t\b ";
  "decimal code" = run pOpamStringSingle "\"0\\123456\"" == "0{456";
  "hex code" = run pOpamStringSingle "\"1\\x2345\"" == "1#45";
  "escaped newline" = run pOpamStringSingle "\"ab\\\ncd\"" == "abcd";
  "triple string" = run pOpamStringTriple "\"\"\"abc\"\"\"" == "abc";
  "empty triple string" = run pOpamStringTriple "\"\"\"\"\"\"" == "";
}
