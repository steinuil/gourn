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

  spToString = { start, len }: substring start len;

  # Type: int -> StringPos -> StringPos

  pStringSp = string: inp:
    let len = stringLength string; in
    if substring inp.pos len == string then
      success (sp inp.pos len) (advance len inp)
    else
      failure "literal string ${string}" inp;

  pCharSp = char: inp:
    if charAt inp.pos inp.buf == char then
      success (sp inp.pos 1) (advance 1 inp)
    else
      failure "literal char ${char}" inp;

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

  pManySp = pManyGeneric catSp (sp 0 0);

  pOr = p1: p2: inp:
    let res = p1 inp; in
    if res.isOk then
      res
    else
      p2 inp;

  pOption = default: p: inp:
    let res = p inp; in
    if res.isOk then res
    else success default inp;

  pBind = p: f: inp:
    let res = p inp; in
    if res.isOk then f res.v res.inp else res;

  pSeqSp = ps: inp:
    let continue = ps: v: inp:
      if length ps == 0 then
        success v inp
      else
        let res = (head ps) inp; in
        if res.isOk then
          continue (tail ps) (catSp v res.v) res.inp
        else
          res;
    in
    continue ps (sp 0 0) inp;
}
