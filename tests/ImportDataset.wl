(* Extract the pinned public source; dataset is input, never executable code. *)
root=ParentDirectory[DirectoryName[$InputFileName]];
source="https://raw.githubusercontent.com/3-manifolds/snappy_15_knots/f3eb9cdd16e1792dd84476a945315049873e8ac1/manifold_src/original_manifold_sources/knots_and_links_through_14.csv";
sourceFile=If[Length[$ScriptCommandLine]>1,Last[$ScriptCommandLine],FileNameJoin[{root,"data","knots_and_links_through_14.csv"}]];
If[!FileExistsQ[sourceFile],URLDownload[source,sourceFile]];
If[!FileExistsQ[sourceFile],Print["Dataset download failed: ",sourceFile];Exit[1]];
stream=OpenRead[sourceFile];header=ReadLine[stream];matches={};
While[(line=ReadLine[stream])=!=EndOfFile,
 If[StringContainsQ[line,",K14n12345,"],AppendTo[matches,line]]];
Close[stream];
If[Length[matches]!=1,Print["Expected one K14n12345 record"];Exit[1]];
(* This particular source row has no quoted fields or embedded commas.
   Reject those cases instead of silently misparsing a general CSV record. *)
If[StringContainsQ[First[matches],"\""],Print["Quoted record requires a CSV parser"];Exit[1]];
keys=StringSplit[header,","];values=StringSplit[First[matches],","];
If[Length[keys]!=Length[values],Print["Unexpected record layout"];Exit[1]];
record=AssociationThread[keys,values];
Do[If[!StringMatchQ[record[key],DigitCharacter..],Exit[1]];record[key]=FromDigits[record[key]],{key,{"id","cusps","betti","tets"}}];
Do[st=StringToStream[record[key]];record[key]=Read[st,Number];Close[st],{key,{"volume","chernsimons"}}];
Export[FileNameJoin[{root,"data","14n12345-record.json"}],record,"RawJSON"];
Export[FileNameJoin[{root,"data","provenance.json"}],<|"Source"->source,"Commit"->"f3eb9cdd16e1792dd84476a945315049873e8ac1","CSV_SHA256"->FileHash[sourceFile,"SHA256","HexString"],"SharedChat"->"https://chatgpt.com/s/cx_6acfd5ee2c588191a692c39b136afa23"|>,"RawJSON"];
Print[record];
