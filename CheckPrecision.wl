root=DirectoryName[$InputFileName];Get[FileNameJoin[{root,"Hyperbolic3Manifolds.wl"}]];
r=Import[FileNameJoin[{root,"data","14n12345-record.json"}],"RawJSON"];
s=Import[FileNameJoin[{root,"outputs","structure.wxf"}],"WXF"];
h=SolveCompleteStructure[DecodeTriangulation[r["triangulation"]],160,65];
If[!AssociationQ[h],Print[h];Exit[1]];
a=<|"HigherWorkingPrecision"->160,"Difference"->ToString[Abs[h["Volume"]-s["Volume"]],InputForm],"AgreesTo60DecimalPlaces"->TrueQ[Abs[h["Volume"]-s["Volume"]]<10^-60]|>;
Export[FileNameJoin[{root,"outputs","precision-check.json"}],a,"RawJSON"];
Print[a];If[!TrueQ[a["AgreesTo60DecimalPlaces"]],Exit[1]];
