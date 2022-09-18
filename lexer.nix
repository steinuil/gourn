{ lib }:
with (import ./parser.nix { inherit lib; });
with (import ./ident.nix { inherit lib; });
with (import ./string.nix { inherit lib; });
with (import ./comment.nix { inherit lib; });
with (import ./value.nix { inherit lib; });
let
  pEmpty = pStringOneOfStr [ " " "\t" "\r" "\n" ];

  pLiteral = name: str: pConst { t = name; } (pCharSp str);

  pVal = name: p: pMap (v: { t = name; v = v; }) p;

  pToken = pChoose [
    (pConst { t = "EOF"; } (pSatisfiesSp (c: c == "")))
    (pConst null pEmpty)
    (pLiteral "LBRACE" "{")
    (pLiteral "RBRACE" "}")
    (pLiteral "LBRACKET" "[")
    (pLiteral "RBRACKET" "]")
    (pConst null pComment)
    (pLiteral "LPAR" "(")
    (pLiteral "RPAR" ")")
    (pVal "STRING" pOpamString)
    (pConst null pLineComment)
    (pVal "BOOL" pBool)
    (pVal "INT" pInt)
    (pVal "IDENT" pIdent)
    (pLiteral "AND" "&")
    (pLiteral "OR" "|")
    (pVal "ENVOP" pEnvOp)
    (pVal "RELOP" pRelOp)
    (pVal "PFXOP" pPrefixOp)
    (pLiteral "COLON" ":")
  ];

  tokenStream = inp:
    let
      get = inp:
        let tok = pToken inp; in
        if !tok.isOk then
          abort "token not found: ${tok.expected}"
        else if tok.v == null then
          get tok.inp
        else
          tok;

      curr = get inp;
    in
    {
      curr = curr.v;
      next = if curr.v.t == "EOF" then null else tokenStream curr.inp;
    };
in
{ inherit tokenStream; }
