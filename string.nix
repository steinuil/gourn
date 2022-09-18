{ lib }:
with (import ./parser.nix { inherit lib; });
let
  inherit (builtins) elem elemAt substring stringLength match add foldl' fromJSON;
  inherit (lib.strings) concatStrings stringToCharacters toInt fixedWidthString;
  inherit (lib.lists) imap0;
  inherit (lib.trivial) toHexString;

  pStringNoEscape = inp: pMap ({ start, len }: substring start len inp.buf)
    (pStringWhileSp (c: !(elem c [ "\\" "\"" ])) "string-inner")
    inp;

  charForDecimalCode = str:
    let
      digits = map toInt (stringToCharacters str);
      asInt = elemAt digits 0 * 100 + elemAt digits 1 * 10 + elemAt digits 2;
      asHex = fixedWidthString 4 "0" (toHexString asInt);
    in
    fromJSON "\"\\u${asHex}\"";

  pDecimalCode =
    (pMap charForDecimalCode
      (pSatisfiesLengthStr 3 (s: match "[0-9]{3}" s != null)));

  charForHexCode = str: fromJSON "\"\\u00${str}\"";

  pHexDigits = pMap (s: charForHexCode (substring 1 2 s))
    (pSatisfiesLengthStr 3 (s: match "x[A-Fa-f0-9]{2}" s != null));

  pEscaped = pMap (s: substring 1 (stringLength s - 1) s)
    (pSeqStr [
      (pCharStr "\\")
      (pChoose [
        pDecimalCode
        pHexDigits
        (pConst "" (pCharStr "\n"))
        (pMap (c: { n = "\n"; r = "\r"; t = "\t"; b = "\b"; }.${c})
          (pSatisfiesStr (c: elem c [ "n" "r" "t" "b" ])))
        (pSatisfiesStr (c: elem c [ "\\" "\"" "'" " " ]))
      ])
    ]);

  pStringInner = pMap concatStrings (pManyList (pOr pStringNoEscape pEscaped));
in
rec {
  pOpamStringSingle = pMap (xs: elemAt xs 1)
    (pSeqList [
      (pCharSp "\"")
      (pOption "" pStringInner)
      (pCharSp "\"")
    ]);

  pOpamStringTriple = pMap (xs: elemAt xs 1)
    (pSeqList [
      (pStringStr "\"\"\"")
      (pOption "" pStringInner)
      (pStringStr "\"\"\"")
    ]);

  pOpamString = pChoose [ pOpamStringTriple pOpamStringSingle ];
}
