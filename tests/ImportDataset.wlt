(* Re-extract the K14n12345 record from the pinned CSV and check it matches the committed data.
   The dataset is input, never executable code. Needs data/knots_and_links_through_14.csv
   (downloaded from the pinned commit if absent). *)
root=ParentDirectory[DirectoryName[$InputFileName]];
source="https://raw.githubusercontent.com/3-manifolds/snappy_15_knots/f3eb9cdd16e1792dd84476a945315049873e8ac1/manifold_src/original_manifold_sources/knots_and_links_through_14.csv";
sourceFile=FileNameJoin[{root,"data","knots_and_links_through_14.csv"}];
If[!FileExistsQ[sourceFile],URLDownload[source,sourceFile]];
provenance=Import[FileNameJoin[{root,"data","provenance.json"}],"RawJSON"];
VerificationTest[FileExistsQ[sourceFile]&&FileHash[sourceFile,"SHA256","HexString"]==provenance["CSV_SHA256"],True,
 TestID->"CSV matches pinned SHA-256"]
matches={};
If[FileExistsQ[sourceFile],
 stream=OpenRead[sourceFile];header=ReadLine[stream];
 While[(line=ReadLine[stream])=!=EndOfFile,If[StringContainsQ[line,",K14n12345,"],AppendTo[matches,line]]];
 Close[stream]];
VerificationTest[Length[matches],1,TestID->"Exactly one K14n12345 row"]
(* This particular source row has no quoted fields or embedded commas.
   Reject those cases instead of silently misparsing a general CSV record. *)
VerificationTest[Length[matches]==1&&!StringContainsQ[First[matches],"\""],True,TestID->"Row is unquoted"]
keys=StringSplit[header,","];values=If[Length[matches]==1,StringSplit[First[matches],","],{}];
VerificationTest[Length[keys]==Length[values],True,TestID->"Row has one value per column"]
record=If[Length[keys]==Length[values],AssociationThread[keys,values],$Failed];
VerificationTest[AssociationQ[record]&&And@@(StringMatchQ[record[#],DigitCharacter..]& /@ {"id","cusps","betti","tets"}),True,
 TestID->"Integer columns are digits"]
If[AssociationQ[record],
 Do[record[key]=FromDigits[record[key]],{key,{"id","cusps","betti","tets"}}];
 Do[st=StringToStream[record[key]];record[key]=Read[st,Number];Close[st],{key,{"volume","chernsimons"}}]];
VerificationTest[record,Import[FileNameJoin[{root,"data","14n12345-record.json"}],"RawJSON"],
 TestID->"Extracted record equals committed data/14n12345-record.json"]
VerificationTest[provenance["Source"]==source&&provenance["Commit"]=="f3eb9cdd16e1792dd84476a945315049873e8ac1",True,
 TestID->"Provenance records pinned source"]
