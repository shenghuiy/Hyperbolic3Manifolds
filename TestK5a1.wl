root=DirectoryName[$InputFileName];
Get[FileNameJoin[{root,"Hyperbolic3Manifolds.wl"}]];
out=FileNameJoin[{root,"outputs","K5a1"}];If[!DirectoryQ[out],CreateDirectory[out]];
require[x_]:=If[!AssociationQ[x],Print["Stage failed: ",x];Exit[1],x];
record=<|"name"->"K5a1","id"->3,"triangulation"->"dLQcbcciirv_BacB","volume"->2.8281220883,"tets"->3,"SourceCommit"->"f3eb9cdd16e1792dd84476a945315049873e8ac1"|>;
Export[FileNameJoin[{out,"record.json"}],record,"RawJSON"];
t=require[DecodeTriangulation[record["triangulation"]]];
top=require[ValidateIdealTriangulation[t]];Print["Topology: ",top];
s=require[SolveCompleteStructure[t,120,45]];Print["Volume: ",N[s["Volume"],50]];
high=require[SolveCompleteStructure[t,160,65]];
h=require[BuildHolonomy[t,s]];
d=require[BuildDirichletDomain[h]];Print["Domain V,E,F: ",Length /@ Lookup[d,{"Vertices","Edges","Faces"}]];
i=require[IntegrateDomainVolume[d,10]];Print["Domain integral: ",i["Volume"]];
checks=<|
"ThreeTetrahedra"->(t["Tetrahedra"]==3),
"OneTorusCusp"->(top["Cusps"]==1&&top["VertexLinkEulerCharacteristics"]=={0}),
"PositiveAngles"->(Min[s["Angles"]]>0&&Max[s["Angles"]]<Pi),
"AngleEquations"->(s["AngleEquationResidual"]<10^-40),
"Stationarity"->(s["GradientResidual"]<10^-45),
"ComplexGluing"->(s["ComplexEdgeResidual"]<10^-40),
"VolumeFormulas"->(Max[Abs[s["Volume"]-{s["BlochWignerVolume"],s["QuadratureVolume"]}]]<10^-40),
"PrecisionStability60Digits"->(Abs[s["Volume"]-high["Volume"]]<10^-60),
"DatasetAgreement"->(Abs[s["Volume"]-record["volume"]]<10^-9),
"FacePairing"->(d["PairingVertexResidual"]<10^-9),
"EdgeAngles"->(d["EdgeCycleAngleResidual"]<10^-9),
"IndependentDomainIntegral"->(Abs[i["Volume"]-s["Volume"]]<10^-7)|>;
summary=<|"Manifold"->record["name"],"Volume"->ToString[N[s["Volume"],50],InputForm],
"DomainVEF"->(Length /@ Lookup[d,{"Vertices","Edges","Faces"}]),
"IdealVertices"->Length[d["IdealVertices"]],
"ComplexEdgeResidual"->ToString[s["ComplexEdgeResidual"],InputForm],
"FacePairingResidual"->d["PairingVertexResidual"],"EdgeAngleResidual"->d["EdgeCycleAngleResidual"],
"DomainIntegral"->N[i["Volume"]],"IntegralDifference"->N[i["Volume"]-s["Volume"]],
"Checks"->checks,"AllPassed"->And@@(TrueQ /@ Values[checks]),"Certification"->"Numerical checks only"|>;
Export[FileNameJoin[{out,"results.json"}],summary,"RawJSON"];
Export[FileNameJoin[{out,"computed.wxf"}],<|"Triangulation"->t,"Topology"->top,"Structure"->s,"Holonomy"->h,"Domain"->d,"Integral"->i|>,"WXF"];
Print[summary];
pg=DomainGraphics[d,"Poincare"];kg=DomainGraphics[d,"Klein"];
Put[Notebook[{Cell["K5a1: independent regression test","Title"],Cell["Computed entirely in Wolfram Language. Numerical checks, not a certified domain.","Text"],Cell["Volume = "<>summary["Volume"],"Text"],Cell[BoxData[ToBoxes[pg]],"Output"],Cell[BoxData[ToBoxes[kg]],"Output"]},StyleDefinitions->"Default.nb"],FileNameJoin[{out,"K5a1.nb"}]];
Export[FileNameJoin[{out,"preview.png"}],GraphicsRow[{pg,kg},ImageSize->1200],"PNG"];
If[!TrueQ[summary["AllPassed"]],Exit[1]];
