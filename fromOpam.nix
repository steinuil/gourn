{ lib }:
let
  inherit (builtins) elem stringLength substring;
  inherit (lib.strings) lowerChars upperChars stringToCharacters;

  isAlpha = c: elem c lowerChars || elem c upperChars;
  isDigit = c: elem c (stringToCharacters "0123456789");
  isDash = c: c == "_" || c == "-";

  charAt = pos: str: substring pos 1 str;
  
  cat = a1: a2:
    if a1 == null then a2 else
    if a2 == null then a1 else
    { inp = a2.inp; v = { start = a1.v.start; len = a1.v.len + a2.v.len; }; };

  pMany = p: inp:
    let keepParsing = acc: inp:
      let res = p inp; in
      if res == null then acc else
      keepParsing (cat acc res) res.inp;
    in
    keepParsing null inp;

  pChar = char: inp:
    if charAt inp.pos inp.buf == char then
      {
        inp = { buf = inp.buf; pos = inp.pos + 1; };
        v = { start = inp.pos; len = 1; };
      }
    else null;
  
  pString = string: inp:
    let len = stringLength string; in
    if substring inp.pos len == string then
      {
        inp = { buf = inp.buf; pos = inp.pos + len; };
        v = { start = inp.pos; len = len; };
      }
    else null;

  pWhile = cond: inp:
    let
      start = inp.pos;
      keepReading = inp@{ buf, pos }:
        let c = charAt pos buf; in
        if cond c then
          keepReading { inherit buf; pos = pos + 1; }
        else
          let len = pos - start; in
          if len == 0 then null else
          { inherit inp; v = { inherit start len; }; };
    in
    keepReading inp;
  
  pId = (import ./ident.nix { inherit lib; }).pId;

  pId' = inp:
    let
      pDigitOrDash = pWhile (c: isDigit c || isDash c);

      pAlpha = pWhile isAlpha;

      pRest = pWhile (c: isAlpha c || isDigit c || isDash c);

      before = pDigitOrDash inp;
      middle =
        let middle' = pAlpha (if before == null then inp else before.inp); in
        if middle' == null then null else
        cat before middle';
      rest =
        if middle == null then null else
        let rest' = pRest middle.inp; in
        cat middle rest';
    in
    rest;
  
  pIdent = (import ./ident.nix { inherit lib; }).pIdent;

  pIdent' = inp:
    let
      pIdOrUnderscore = inp:
        let id = pId inp; in
        if id != null then id else
        pChar "_" inp;

      pPlusId = inp:
        let plus = pChar "+" inp; in
        if plus == null then null else
        let id = pIdOrUnderscore plus.inp; in
        if id == null then null else cat plus id;

      pColonId = inp:
        let colon = pChar ":" inp; in
        if colon == null then null else
        let id = pIdOrUnderscore colon.inp; in
        if id == null then null else cat colon id;

      begin = pIdOrUnderscore inp;
      rest =
        if begin == null then null else
        cat begin (pMany pPlusId begin.inp);
      colon =
        if rest == null then null else
        cat rest (pColonId rest.inp);
    in
    colon;
in
{
  # fromOpamFile = filename: { };
  inherit pId pIdent;
}
