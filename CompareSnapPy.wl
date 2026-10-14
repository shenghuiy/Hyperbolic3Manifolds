root=DirectoryName[$InputFileName];Get[FileNameJoin[{root,"Hyperbolic3Manifolds.wl"}]];
out=FileNameJoin[{root,"outputs","snappy-comparison"}];
records=Import[FileNameJoin[{out,"samples.json"}],"RawJSON"];
If[!ListQ[records]||Length[records]!=10,Print["Expected ten samples"];Exit[1]];
results={};
Do[
 Print["Solving ",r["name"]];
 elapsed=AbsoluteTiming[
 result=TimeConstrained[
  t=DecodeTriangulation[r["triangulation"]];
  If[!AssociationQ[t],<|"Name"->r["name"],"Status"->"DecodeFailure","Failure"->ToString[t,InputForm]|>,
   s=SolveCompleteStructure[t,120,45];
   If[!AssociationQ[s],<|"Name"->r["name"],"Status"->"SolveFailure","Failure"->ToString[s,InputForm]|>,
    Export[FileNameJoin[{out,r["name"]<>"-structure.wxf"}],s,"WXF"];
    <|"Name"->r["name"],"Status"->"Success","Tetrahedra"->t["Tetrahedra"],
      "Volume"->ToString[NumberForm[N[s["Volume"],80],{82,70},ExponentFunction->(Null&),NumberPadding->{"","0"}],OutputForm],
      "ComplexEdgeResidual"->ToString[s["ComplexEdgeResidual"],InputForm],
      "StationarityResidual"->ToString[s["GradientResidual"],InputForm],
      "ChecksPassed"->TrueQ[s["ComplexEdgeResidual"]<10^-40&&s["AngleEquationResidual"]<10^-40&&
        s["GradientResidual"]<10^-45&&Min[s["Angles"]]>0&&
        Max[Abs[s["Volume"]-{s["BlochWignerVolume"],s["QuadratureVolume"]}]]<10^-40]|>
   ]],180,<|"Name"->r["name"],"Status"->"Timeout"|>];][[1]];
 result=Append[result,"Seconds"->elapsed];AppendTo[results,result];
 Export[FileNameJoin[{out,"wolfram.json"}],results,"RawJSON"];Print[result],{r,records}];
