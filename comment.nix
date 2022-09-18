{ lib }:
with (import ./parser.nix { inherit lib; });
let
  inherit (lib.strings) concatStrings;

  pCommentText = pStringWhileStr (c: c != "*" && c != "(") "comment text";

  pNotEnd = pSatisfiesLengthStr 2 (c: c != "*)" && c != "(*");

  pCommentInner = pMap concatStrings
    (pManyList (pChoose [
      pCommentText
      pNotEnd
      pComment
    ]));

  pComment = pMap concatStrings
    (pSeqList [
      (pStringStr "(*")
      pCommentInner
      (pStringStr "*)")
    ]);
    
  pNotNewline = pStringWhileStr (c: c != "\n") "not newline";
    
  pLineComment = pMap concatStrings
    (pSeqList [
      (pCharStr "#")
      pNotNewline
      (pCharStr "\n")
    ]);
in
{ inherit pComment pLineComment; }
