root=ParentDirectory[DirectoryName[$InputFileName]];
Get[FileNameJoin[{root,"src","Hyperbolic3Manifolds.wl"}]];
Get[FileNameJoin[{root,"src","DTCrossingTable.wl"}]];
Get[FileNameJoin[{root,"src","DTKnotDiagram.wl"}]];
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
(* K15n4321 DT code from SnapPy; crossing (1,4) has the even visit under and (19,6),(7,18) have it over. *)
dt15={4,8,10,-18,2,24,26,28,22,-6,16,20,30,14,12};
dtTable=DTCrossingTable[dt15];
VerificationTest[{dtTable["Crossings"],Length[dtTable["Table"]],Sort[Join@@Lookup[dtTable["Table"],{"OddVisit","EvenVisit"}]]},
 {15,15,Range[30]},TestID->"DT code visits each of 30 labels once"]
VerificationTest[Lookup[Select[dtTable["Table"],#["Over"]=="Even"&],"EvenVisit"],{18,6},TestID->"DT code over-strand signs"]
VerificationTest[And@@(FailureQ[DTCrossingTable[#]]& /@ {{},{4,6,2,8,8},{3,6,2},{4,2,2}}),True,TestID->"Malformed DT codes fail"]
(* DTKnotDiagram. The PD codes and flips below are SnapPy's (spherogram DTcodec) for the same codes, pinned as constants. *)
VerificationTest[Sort[DTPlanarData[{-6,-8,-2,-4},{0,1,1,0}]["PD"]],{{2,8,3,7},{4,1,5,2},{6,4,7,3},{8,5,1,6}},TestID->"DT PD code, explicit flips (SnapPy docstring)"]
VerificationTest[With[{d=DTPlanarData[{4,6,8,2}]},{d["Flips"],Sort[d["PD"]]}],
 {{0,1,0,0},{{1,6,2,7},{3,1,4,8},{5,2,6,3},{7,5,8,4}}},TestID->"Figure-eight flips and PD match SnapPy"]
VerificationTest[With[{d=DTPlanarData[dt15]},{d["Flips"],Sort[d["PD"]]}],
 {{0,1,0,1,0,0,1,1,1,0,0,0,0,0,0},{{1,8,2,9},{3,1,4,30},{6,18,7,17},{7,2,8,3},{9,5,10,4},{11,28,12,29},{13,26,14,27},{15,20,16,21},{18,6,19,5},{19,22,20,23},{21,16,22,17},{23,11,24,10},{25,12,26,13},{27,14,28,15},{29,25,30,24}}},
 TestID->"K15n4321 flips and PD match SnapPy"]
VerificationTest[With[{d=DTPlanarData[record["DT"]]},{d["Code"],d["Flips"],Sort[d["PD"]]}],
 {{4,10,-18,-22,2,-26,-28,-24,-6,-14,-8,-16,-20,-12},{0,0,0,0,1,1,1,0,1,0,1,1,0,0},
  {{1,9,2,8},{3,1,4,28},{4,17,5,18},{6,21,7,22},{9,3,10,2},{10,26,11,25},{12,28,13,27},{14,23,15,24},{16,5,17,6},{18,14,19,13},{20,7,21,8},{22,15,23,16},{24,20,25,19},{26,12,27,11}}},
 TestID->"K14n12345 letter code with flip suffix"]
VerificationTest[DTPlanarData[record["DT"]]["Flips"]==DTPlanarData[DTPlanarData[record["DT"]]["Code"]]["Flips"],True,
 TestID->"K14n12345 searched flips equal the dataset flips"]
VerificationTest[And@@(FailureQ /@ {DTPlanarData[{4,6,8,10,2}],DTPlanarData[{4,6,8,2},{1,1,1,1}],DTPlanarData[{4,6,8,2},{0,1}],
 DTPlanarData[{4,6}],DTPlanarData["bad"],DTPlanarData["bad.01"],DTDiagramLayout[DTPlanarData[{2}]]}),True,
 TestID->"Non-planar, malformed and kinked DT input fails"]
cross2[a_,b_]:=a[[1]] b[[2]]-a[[2]] b[[1]];
segsCross[{p_,q_},{r_,s_}]:=cross2[q-p,r-p] cross2[q-p,s-p]<-10^-12&&cross2[s-r,p-r] cross2[s-r,q-r]<-10^-12;
diagramOK[code_]:=Module[{d=DTPlanarData[code],lay,cv,segs,ccw},
 lay=DTDiagramLayout[d];cv=lay["Curves"];
 segs=Join@@Table[Partition[cv[k],2,1],{k,2 d["Crossings"]}];
 ccw=And@@Table[With[{a=ArcTan@@@Table[If[dd[[2]]==0,cv[dd[[1]]][[2]]-cv[dd[[1]]][[1]],cv[dd[[1]]][[2]]-cv[dd[[1]]][[3]]],{dd,d["Rotation"][c]}]},
  Abs[Total[Mod[RotateLeft[a]-a,2 Pi]]-2 Pi]<10^-6],{c,d["Crossings"]}];
 ccw&&!AnyTrue[Subsets[segs,{2}],segsCross@@#&]];
VerificationTest[diagramOK /@ {{4,6,2},{4,6,8,2},dt15,DTPlanarData[record["DT"]]["Code"]},{True,True,True,True},TestID->"DT layouts are planar with the rotation order of the embedding"]
VerificationTest[Head[DTKnotDiagram[dt15]]===Graphics&&Head[DTKnotDiagram[record["DT"]]]===Graphics,True,TestID->"DTKnotDiagram draws codes and letter strings"]
