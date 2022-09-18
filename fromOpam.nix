{ lib }:
let
  inherit (builtins) length elem;
  inherit (import ./parser.nix { inherit lib; }) success failure pChoose pOr pBetween pSeqList pMap pManyList;
  inherit (import ./lexer.nix { inherit lib; }) tokenStream;

  curr = stream: stream.curr;
  next = stream:
    if stream.next == null then
      { curr = { t = "EOF"; }; next = null; }
    else
      stream.next;

  pTokenType = t: inp:
    if (curr inp).t == t then
      success (curr inp) (next inp)
    else
      failure "token of type ${t}" inp;

  pAtom = pChoose [
    (pTokenType "IDENT")
    (pTokenType "BOOL")
    (pTokenType "INT")
    (pTokenType "STRING")
  ];

  pValue = pChoose [
    pAtom

    (pMap (items: { t = "GROUP"; inherit items; })
      (pBetween (pTokenType "LPAR") pValues (pTokenType "RPAR")))

    (pMap (items: { t = "LIST"; inherit items; })
      (pBetween (pTokenType "LBRACKET") pValues (pTokenType "RBRACKET")))

    # LEFT RECURSION LOL
    (pMap (items: { t = "OPTION"; v = elem 0 items; options = elem 2 items; })
      (pSeqList [ pValue (pTokenType "LBRACE") pValues (pTokenType "RBRACE") ]))

    (pMap (items: { t = "LOGOP"; l = elem 0 items; r = elem 2 items; })
      (pSeqList [ pValue (pOr (pTokenType "AND") (pTokenType "OR")) pValue ]))

    (pMap (items: { t = (elem 1 items).t; l = elem 0 items; r = elem 2 items; })
      (pSeqList [ pValue (pOr (pTokenType "RELOP") (pTokenType "ENVOP")) pValue ]))

    (pMap (items: { t = "PFXOP"; v = elem 1 items; })
      (pSeqList [ (pTokenType "PFXOP") pValue ]))

    (pMap (items: { t = "RELOP"; v = elem 1 items; })
      (pSeqList [ (pTokenType "RELOP") pAtom ]))
  ];

  pValues = pManyList pValue;

  pItem = pChoose [
    (pMap (items: { t = "VARIABLE"; name = (elem 0 items).v; v = elem 2 items; })
      (pSeqList [ (pTokenType "IDENT") (pTokenType "COLON") pValue ]))

    (pMap (items: { t = "SECTION"; kind = (elem 0 items).v; name = null; items = elem 2 items; })
      (pSeqList [ (pTokenType "IDENT") (pTokenType "LBRACE") pItems (pTokenType "RBRACE") ]))

    (pMap (items: { t = "SECTION"; kind = (elem 0 items).v; name = (elem 1 items).v; items = elem 3 items; })
      (pSeqList [ (pTokenType "IDENT") (pTokenType "STRING") (pTokenType "LBRACE") pItems (pTokenType "RBRACE") ]))
  ];

  pItems = pManyList pItem;

  pOpamFile = pMap (items: elem 0 items) (pSeqList [ pItems (pTokenType "EOF") ]);
  
  run = p: str: p (tokenStream { buf = str; pos = 0; });
in
{
  fromOpamFile = run pOpamFile;
}
