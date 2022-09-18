{ lib }:
let
  inherit (builtins) elem stringLength substring head tail length;
  inherit (lib.strings) lowerChars upperChars stringToCharacters;
  inherit (lib.lists) foldl;
in
rec {
  # Input = { buf = string; pos = int; }
  # Success<T> = { ok = true; inp = Input; v = T; }
  # Failure = { ok = false; inp = Input; expected = string; }
  # Result<T> = Success<T> | Failure

  # Type: T -> Input -> Success<T>
  success = v: inp: { isOk = true; inherit inp v; };

  # Type: string -> Input -> Failure
  failure = expected: inp: { isOk = false; inherit inp expected; };

  # Type: int -> Input -> Input
  advance = n: { buf, pos }: { inherit buf; pos = pos + n; };

  charAt = pos: str: substring pos 1 str;

  # StringPos = { start = int; len = int; }

  sp = start: len: { inherit start len; };

  spToString = buf: { start, len }: substring start len buf;

  pStringSp = string: inp:
    let len = stringLength string; in
    if substring inp.pos len inp.buf == string then
      success (sp inp.pos len) (advance len inp)
    else
      failure "literal string ${string}" inp;

  pStringStr = string: inp:
    let len = stringLength string; in
    if substring inp.pos len inp.buf == string then
      success string (advance len inp)
    else
      failure "literal string ${string}" inp;

  pCharSp = char: inp:
    if charAt inp.pos inp.buf == char then
      success (sp inp.pos 1) (advance 1 inp)
    else
      failure "literal char ${char}" inp;

  pCharStr = char: inp:
    if charAt inp.pos inp.buf == char then
      success char (advance 1 inp)
    else
      failure "literal char ${char}" inp;

  pSatisfiesSp = cond: inp:
    if cond (charAt inp.pos inp.buf) then
      success (sp inp.pos 1) (advance 1 inp)
    else
      failure "char not satisfactory" inp;

  pSatisfiesStr = cond: inp:
    let c = charAt inp.pos inp.buf; in
    if cond c then
      success c (advance 1 inp)
    else
      failure "char not satisfactory" inp;

  pSatisfiesLengthStr = n: cond: inp:
    let str = substring inp.pos n inp.buf; in
    if cond str then
      success str (advance n inp)
    else
      failure "char not satisfactory" inp;

  pStringOneOfStr = strs: inp:
    let continue = strs:
      if length strs == 0 then
        failure "none matched" inp
      else
        let
          str = (head strs);
          len = stringLength str;
        in
        if substring inp.pos len inp.buf == str then
          success str (advance len inp)
        else
          continue (tail strs);
    in
    continue strs;

  pStringWhileSp = cond: condName: inp:
    let
      start = inp.pos;
      continue = inp@{ buf, pos }:
        let c = charAt pos buf; in
        if cond c then
          continue (advance 1 inp)
        else
          let len = pos - start; in
          if len == 0 then failure "char satisfying ${condName}" inp
          else success (sp start len) inp;
    in
    continue inp;

  pStringWhileStr = cond: condName: inp:
    pMap ({ start, len }: substring start len inp.buf) (pStringWhileSp cond condName) inp;

  catSp = a1: a2: sp a1.start (a1.len + a2.len);

  pManyGeneric = combine: initial: p: inp:
    let continue = acc: inp:
      let res = p inp; in
      if res.isOk then
        continue (combine acc res.v) res.inp
      else
        success acc inp;
    in
    continue initial inp;

  pManyList = pManyGeneric (a: b: a ++ [ b ]) [ ];

  pManySp = pManyGeneric catSp (sp 0 0);

  pManyStr = pManyGeneric (a: b: a + b) "";

  pMany1Str = ps: pBind (v: if v == "" then failure "" else success v)
    (pManyStr ps);

  pOr = p1: p2: inp:
    let res = p1 inp; in
    if res.isOk then
      res
    else
      p2 inp;

  pChoose = ps: inp:
    let continue = ps:
      if length ps == 0 then
        failure "Choose item not found" inp
      else
        let res = (head ps) inp; in
        if res.isOk then
          res
        else
          continue (tail ps);
    in
    continue ps;

  pOption = default: p: inp:
    let res = p inp; in
    if res.isOk then res
    else success default inp;

  pOptionSp = p: inp: pOption (sp inp.pos 0) p inp;

  pBind = f: p: inp:
    let res = p inp; in
    if res.isOk then f res.v res.inp else res;

  pConst = c: pMap (x: c);

  pSeqGeneric = combine: initial: ps: inp:
    let
      continue = ps: v: inp:
        if length ps == 0 then
          success v inp
        else
          let res = (head ps) inp; in
          if res.isOk then
            continue (tail ps) (combine v res.v) res.inp
          else
            res;
    in
    continue ps initial inp;

  pSeqList = pSeqGeneric (a: b: a ++ [ b ]) [ ];

  pSeqStr = pSeqGeneric (a: b: a + b) "";

  pSeqSp = ps: inp: pSeqGeneric catSp (sp inp.pos 0) ps inp;

  pMap = f: p: inp:
    let res = p inp; in
    if res.isOk then
      success (f res.v) res.inp
    else
      res;

  isAlpha = c: elem c lowerChars || elem c upperChars;
  isDigit = c: elem c (stringToCharacters "0123456789");

  pBetween = p1: p2: p3: pMap (ls: elem 1 ls)
    (pSeqList [
      p1
      p2
      p3
    ]);
}
