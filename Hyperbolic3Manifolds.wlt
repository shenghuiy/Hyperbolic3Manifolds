root=DirectoryName[$InputFileName];
Get[FileNameJoin[{root,"Hyperbolic3Manifolds.wl"}]];
record=Import[FileNameJoin[{root,"data","14n12345-record.json"}],"RawJSON"];
tri=DecodeTriangulation[record["triangulation"]];
VerificationTest[tri["Tetrahedra"],20,TestID->"Dataset tetrahedron count"]
VerificationTest[ValidateIdealTriangulation[tri],<|"Cusps"->1,"VertexLinkEulerCharacteristics"->{0},"ReversedEdges"->False|>,TestID->"One torus cusp and no reversed edges"]
VerificationTest[And@@Table[
 With[{back=tri["FacePairings"][[4 r["neighbor"]+r["vertex_permutation"][[r["face"]+1]]+1]]},
 back["neighbor"]==r["tetrahedron"]&&back["vertex_permutation"][[r["vertex_permutation"]+1]]==Range[0,3]],
 {r,tri["FacePairings"]}],True,TestID->"All 80 pairings reciprocal"]
VerificationTest[And@@(FailureQ[DecodeTriangulation[#]]& /@ {"","bad!signature","u","uvvzwPwMAzPAQQchellhjokjqqsprtprtrstavtlgolkkpdbgclbotcb"}),True,
 TestID->"Malformed and truncated signatures fail"]
VerificationTest[MatrixRank[AngleSystem[tri]["Matrix"]],39,TestID->"Exact angle rank"]
VerificationTest[Dimensions[AngleSystem[tri]["NullSpace"]],{21,60},TestID->"21 independent angle deformations"]
structure=Import[FileNameJoin[{root,"outputs","structure.wxf"}],"WXF"];
domain=Import[FileNameJoin[{root,"outputs","domain.wxf"}],"WXF"];
integral=Import[FileNameJoin[{root,"outputs","domain-integral.wxf"}],"WXF"];
VerificationTest[AssociationQ[structure]&&AssociationQ[domain]&&AssociationQ[integral],True,TestID->"Complete computed artifacts"]
VerificationTest[Min[structure["Angles"]]>0&&Max[structure["Angles"]]<Pi,True,TestID->"Strictly positive tetrahedra"]
VerificationTest[structure["AngleEquationResidual"]<10^-40&&structure["GradientResidual"]<10^-45,True,TestID->"Feasibility and stationarity"]
VerificationTest[Max[Abs[structure["Volume"]-{structure["BlochWignerVolume"],structure["QuadratureVolume"]}]]<10^-40,True,
 TestID->"Independent tetrahedral volume formulas"]
VerificationTest[structure["ComplexEdgeResidual"]<10^-40,True,TestID->"Complex edge equations"]
VerificationTest[Abs[structure["Volume"]-record["volume"]]<10^-8,True,TestID->"Agreement with rounded database reference"]
VerificationTest[domain["FacePairs"][[domain["FacePairs"]]]==Range[Length[domain["Faces"]]],True,TestID->"Domain pairings involutive"]
VerificationTest[domain["PairingVertexResidual"]<10^-9&&domain["EdgeCycleAngleResidual"]<10^-9,True,TestID->"Domain face and angle checks"]
VerificationTest[Abs[integral["Volume"]-structure["Volume"]]<10^-7,True,TestID->"Independent polyhedral integration"]
(* Different triangulation: the two-tetrahedron figure-eight complement. *)
figureEight=SolveCompleteStructure[DecodeTriangulation["cPcbbbiht"],80,25];
VerificationTest[AssociationQ[figureEight]&&Abs[figureEight["Volume"]-2 Im[PolyLog[2,Exp[I Pi/3]]]]<10^-24,True,
 TestID->"Figure-eight exact volume regression"]
