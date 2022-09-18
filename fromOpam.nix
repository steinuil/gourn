{ lib }:
let
  inherit (builtins) length elemAt;
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

    (pMap (items: { t = "PFXOP"; v = elemAt items 1; })
      (pSeqList [ (pTokenType "PFXOP") pValue ]))

    (pMap (items: { t = "RELOP"; v = elemAt items 1; })
      (pSeqList [ (pTokenType "RELOP") pAtom ]))

    # LEFT RECURSION LOL
    # (pMap (items: { t = "OPTION"; v = elemAt items 0; options = elemAt items 2; })
    #   (pSeqList [ pValue (pTokenType "LBRACE") pValues (pTokenType "RBRACE") ]))

    # (pMap (items: { t = "LOGOP"; l = elemAt items 0; r = elemAt items 2; })
    #   (pSeqList [ pValue (pOr (pTokenType "AND") (pTokenType "OR")) pValue ]))

    # (pMap (items: { t = (elemAt items 1).t; l = elemAt items 0; r = elemAt items 2; })
    #   (pSeqList [ pValue (pOr (pTokenType "RELOP") (pTokenType "ENVOP")) pValue ]))

  ];

  pValues = pManyList pValue;

  pItem = pChoose [
    (pMap (items: { t = "VARIABLE"; name = (elemAt items 0).v; v = elemAt items 2; })
      (pSeqList [ (pTokenType "IDENT") (pTokenType "COLON") pValue ]))

    (pMap (items: { t = "SECTION"; kind = (elemAt items 0).v; name = null; items = elemAt items 2; })
      (pSeqList [ (pTokenType "IDENT") (pTokenType "LBRACE") pItems (pTokenType "RBRACE") ]))

    (pMap (items: { t = "SECTION"; kind = (elemAt items 0).v; name = (elemAt items 1).v; items = elemAt items 3; })
      (pSeqList [ (pTokenType "IDENT") (pTokenType "STRING") (pTokenType "LBRACE") pItems (pTokenType "RBRACE") ]))
  ];

  pItems = pManyList pItem;

  pOpamFile = pMap (items: elemAt items 0) (pSeqList [ pItems (pTokenType "EOF") ]);
  
  run = p: str: p (tokenStream { buf = str; pos = 0; });
in
{
  fromOpamFile = run pOpamFile;
}
