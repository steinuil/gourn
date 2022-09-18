{ lib }:
with (import ./parser.nix { inherit lib; });
let
  inherit (builtins) elem filter;
  inherit (lib.strings) concatStrings stringToCharacters toInt;

  stringFilter = f: s: concatStrings (filter f (stringToCharacters s));
in
{
  pRelOp = pStringOneOfStr [ "=" "!=" ">=" "<=" ">" "<" "~" ];

  pPrefixOp = pStringOneOfStr [ "!" "?" ];

  pEnvOp = pStringOneOfStr [ "=+=" "=:=" "+=" ":=" "=+" "=:" ];

  pInt = pMap (s: toInt (stringFilter (c: c != "_") s))
    (pSeqStr [
      (pOption "" (pCharStr "-"))
      (pMany1Str (pSatisfiesStr (c: isDigit c || c == "_")))
    ]);

  pBool = pMap (b: b == "true") (pStringOneOfStr [ "true" "false" ]);
}
