{ lib }:
with (import ./parser.nix { inherit lib; });
let
  inherit (builtins) elem substring;
  inherit (lib.strings) lowerChars upperChars stringToCharacters;

  isDash = c: c == "_" || c == "-";

  pDigitOrDash = pStringWhileSp (c: isDigit c || isDash c) "digit-or-dash";

  pAlpha = pStringWhileSp isAlpha "alpha";

  pAlphaNumericOrDash = pStringWhileSp (c: isAlpha c || isDigit c || isDash c)
    "alphanumeric-or-dash";

  pId = pSeqSp [
    (pOptionSp pDigitOrDash)
    pAlpha
    (pOptionSp pAlphaNumericOrDash)
  ];

  pIdOrUnderscore = pOr pId (pCharSp "_");

  pPlusId = pSeqSp [ (pCharSp "+") pIdOrUnderscore ];

  pColonId = pSeqSp [ (pCharSp ":") pId ];

  pIdentSp = pSeqSp [
    pIdOrUnderscore
    (pManySp pPlusId)
    (pOptionSp pColonId)
  ];
in
{
  pIdent = inp: pMap ({ start, len }: substring start len inp.buf) pIdentSp inp;
}
