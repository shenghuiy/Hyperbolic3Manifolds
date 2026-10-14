(* Builds results.json, the rotatable notebook, and the preview PNG from the saved
   K14n12345 artifacts. Run after Run14n12345.wlt. *)
started=Floor[AbsoluteTime[]];
root=ParentDirectory[DirectoryName[$InputFileName]];out=FileNameJoin[{root,"outputs"}];
Get[FileNameJoin[{root,"src","Hyperbolic3Manifolds.wl"}]];
record=Import[FileNameJoin[{root,"data","14n12345-record.json"}],"RawJSON"];
structure=Import[FileNameJoin[{out,"structure.wxf"}],"WXF"];
domain=Import[FileNameJoin[{out,"domain.wxf"}],"WXF"];
integral=Import[FileNameJoin[{out,"domain-integral.wxf"}],"WXF"];
VerificationTest[And@@(AssociationQ /@ {record,structure,domain,integral}),True,TestID->"Load saved artifacts"]
decimal[x_]:=ToString[N[x,55],InputForm];
summary=<|"Knot"->record["name"],"Tetrahedra"->record["tets"],
 "ComputedVolume"->decimal[structure["Volume"]],
 "BlochWignerVolume"->decimal[structure["BlochWignerVolume"]],
 "LobachevskyQuadratureVolume"->decimal[structure["QuadratureVolume"]],
 "DatabaseVolumeForComparisonOnly"->record["volume"],
 "StationarityResidual"->decimal[structure["GradientResidual"]],
 "AngleEquationResidual"->decimal[structure["AngleEquationResidual"]],
 "ComplexEdgeResidual"->decimal[structure["ComplexEdgeResidual"]],
 "MinimumAngle"->N[structure["MinimumAngle"]],
 "DomainVertices"->Length[domain["Vertices"]],"DomainEdges"->Length[domain["Edges"]],
 "DomainFaces"->Length[domain["Faces"]],"DomainIdealVertices"->Length[domain["IdealVertices"]],
 "FacePairingResidual"->domain["PairingVertexResidual"],
 "EdgeCycleAngleResidual"->domain["EdgeCycleAngleResidual"],
 "DomainIntegral"->N[integral["Volume"]],
 "DomainIntegralDifference"->N[integral["Volume"]-structure["Volume"]],
 "Certification"->"Numerical evidence only; not an interval or fundamental-domain proof",
 "Kernel"->$Version|>;
Export[FileNameJoin[{out,"results.json"}],summary,"RawJSON"];
VerificationTest[Import[FileNameJoin[{out,"results.json"}],"RawJSON"]["DomainFaces"],84,TestID->"Write results.json"]
pg=DomainGraphics[domain,"Poincare"];
kg=DomainGraphics[domain,"Klein"];
nb=Notebook[{
 Cell["K14n12345: a Wolfram computation","Title"],
 Cell["From a triangulation signature to hyperbolic volume and a candidate Dirichlet domain","Subtitle"],
 Cell["All geometry is computed in Wolfram Language. The public SnapPy dataset supplies combinatorial input only; no SnapPy, SnapPea, Regina, or Python runtime is called.","Text"],
 Cell["Volume = "<>ToString[NumberForm[structure["Volume"],{48,43}]],"Text"],
 Cell["Drag each graphic to rotate. Orange points are ideal vertices; the center point is the chosen Dirichlet basepoint. There are "<>ToString[Length[domain["Faces"]]]<>" faces. Both models depict the same hyperbolic polyhedron.","Text"],
 Cell["Poincare ball","Section"],Cell[BoxData[ToBoxes[pg]],"Output"],
 Cell["Klein ball","Section"],Cell[BoxData[ToBoxes[kg]],"Output"],
 Cell["What was checked","Section"],
 Cell["Positive angles, angle constraints, complex gluing equations, stationarity of volume, reciprocal domain face identifications, edge-angle sums, and independent integration over the polyhedron. Domain geometry uses machine precision. These are numerical checks, not a certification of discreteness or a complete Poincare polyhedron theorem verification.","Text"],
 Cell[BoxData[ToBoxes[Grid[KeyValueMap[{#1,ToString[#2,InputForm]}&,summary],Alignment->Left,Frame->All]]],"Output"],
 Cell["Recompute","Section"],
 Cell["Evaluate the following cell with this notebook in the outputs directory. It reruns the full pipeline test suite.","Text"],
 Cell[BoxData[ToBoxes[Defer[TestReport[FileNameJoin[{ParentDirectory[NotebookDirectory[]],"tests","Run14n12345.wlt"}]]]]],"Input"]
 },WindowTitle->"K14n12345 — Wolfram",StyleDefinitions->"Default.nb"];
Put[nb,FileNameJoin[{out,"14n12345-Wolfram.nb"}]];
Export[FileNameJoin[{out,"domain-preview.png"}],GraphicsRow[{pg,kg},ImageSize->1400],"PNG"];
VerificationTest[Head /@ {pg,kg},{Graphics3D,Graphics3D},TestID->"Render Poincare and Klein views"]
VerificationTest[AbsoluteTime[FileDate[FileNameJoin[#]]]>=started& /@ {{out,"14n12345-Wolfram.nb"},{out,"domain-preview.png"}},{True,True},TestID->"Write notebook and preview"]
