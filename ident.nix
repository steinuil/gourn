{ lib }:
with (import ./parser.nix { inherit lib; });
let
  inherit (builtins) elem;
  inherit (lib.strings) lowerChars upperChars stringToCharacters;

  isAlpha = c: elem c lowerChars || elem c upperChars;
  isDigit = c: elem c (stringToCharacters "0123456789");
  isDash = c: c == "_" || c == "-";

  pDigitOrDash = pStringWhileSp (c: isDigit c || isDash c) "digit-or-dash";

  pAlpha = pStringWhileSp isAlpha "alpha";

  pAlphaNumericOrDash = pStringWhileSp (c: isAlpha c || isDigit c || isDash c)
    "alphanumeric-or-dash";

  pId = pSeqSp [
    (pOption (sp 0 0) pDigitOrDash)
    pAlpha
    (inp: pOption (sp inp.pos 0) pAlphaNumericOrDash inp)
  ];

  pIdOrUnderscore = pOr pId (pCharSp "_");

  pPlusId = pSeqSp [ (pCharSp "+") pIdOrUnderscore ];

  pColonId = pSeqSp [ (pCharSp ":") pId ];
in
{
  pIdent = pSeqSp [
    pIdOrUnderscore
    (pManySp pPlusId)
    (inp: pOption (sp inp.pos 0) pColonId inp)
  ];
}
