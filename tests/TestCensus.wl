root=ParentDirectory[DirectoryName[$InputFileName]];
Get[FileNameJoin[{root,"src","Hyperbolic3Manifolds.wl"}]];
require[x_]:=If[!AssociationQ[x],Print["Stage failed: ",x];Exit[1],x];
(* Signatures from SnapPy 3.3.2: Manifold(name).triangulation_isosig(decorated=False).
   The SnapPy volumes are used only for comparison, never as input. *)
records={
<|"name"->"m412","triangulation"->"fLLQcbdeedemnamjp","volume"->5.0747080320,"tets"->5,"cusps"->2|>,
<|"name"->"m203","triangulation"->"eLMkbcddddedde","volume"->4.0597664256,"tets"->4,"cusps"->2|>};
run[record_]:=Module[{out,t,top,s,h,d,i,checks,summary,pg,kg},
out=FileNameJoin[{root,"outputs",record["name"]}];If[!DirectoryQ[out],CreateDirectory[out]];
Export[FileNameJoin[{out,"record.json"}],record,"RawJSON"];
t=require[DecodeTriangulation[record["triangulation"]]];
top=require[ValidateIdealTriangulation[t]];
s=require[SolveCompleteStructure[t,120,45]];
h=require[BuildHolonomy[t,s]];
d=require[BuildDirichletDomain[h]];
i=require[IntegrateDomainVolume[d,10]];
checks=<|
"Tetrahedra"->(t["Tetrahedra"]==record["tets"]),
"TorusCusps"->(top["Cusps"]==record["cusps"]&&top["VertexLinkEulerCharacteristics"]==ConstantArray[0,record["cusps"]]),
"PositiveAngles"->(Min[s["Angles"]]>0&&Max[s["Angles"]]<Pi),
"AngleEquations"->(s["AngleEquationResidual"]<10^-40),
"Stationarity"->(s["GradientResidual"]<10^-45),
"ComplexGluing"->(s["ComplexEdgeResidual"]<10^-40),
"VolumeFormulas"->(Max[Abs[s["Volume"]-{s["BlochWignerVolume"],s["QuadratureVolume"]}]]<10^-40),
"ReferenceAgreement"->(Abs[s["Volume"]-record["volume"]]<10^-9),
"IdealVertices"->(Length[d["IdealVertices"]]==record["cusps"]),
"FacePairing"->(d["PairingVertexResidual"]<10^-9),
"EdgeAngles"->(d["EdgeCycleAngleResidual"]<10^-9),
"IndependentDomainIntegral"->(Abs[i["Volume"]-s["Volume"]]<10^-7)|>;
summary=<|"Manifold"->record["name"],"Volume"->ToString[N[s["Volume"],50],InputForm],
"DomainVEF"->(Length /@ Lookup[d,{"Vertices","Edges","Faces"}]),
"IdealVertices"->Length[d["IdealVertices"]],
"FacePairingResidual"->d["PairingVertexResidual"],"EdgeAngleResidual"->d["EdgeCycleAngleResidual"],
"DomainIntegral"->N[i["Volume"]],"IntegralDifference"->N[i["Volume"]-s["Volume"]],
"Checks"->checks,"AllPassed"->And@@(TrueQ /@ Values[checks]),"Certification"->"Numerical checks only"|>;
Export[FileNameJoin[{out,"results.json"}],summary,"RawJSON"];
Print[summary];
pg=DomainGraphics[d,"Poincare"];kg=DomainGraphics[d,"Klein"];
Export[FileNameJoin[{out,"preview.png"}],GraphicsRow[{pg,kg},ImageSize->1200],"PNG"];
summary["AllPassed"]];
If[!And@@(TrueQ[run[#]]&/@records),Exit[1]];
