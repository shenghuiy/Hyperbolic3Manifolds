(* Can be run separately after Run14n12345.wl to refresh presentation. *)
root=DirectoryName[$InputFileName];out=FileNameJoin[{root,"outputs"}];
Get[FileNameJoin[{root,"src","Hyperbolic3Manifolds.wl"}]];
record=Import[FileNameJoin[{root,"data","14n12345-record.json"}],"RawJSON"];
structure=Import[FileNameJoin[{out,"structure.wxf"}],"WXF"];
domain=Import[FileNameJoin[{out,"domain.wxf"}],"WXF"];
integral=Import[FileNameJoin[{out,"domain-integral.wxf"}],"WXF"];
If[!And@@(AssociationQ /@ {record,structure,domain,integral}),Print["Missing computed artifacts"];Exit[1]];
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
Print["Rendering Poincare model."];
pg=DomainGraphics[domain,"Poincare"];
Print["Rendering Klein model."];
kg=DomainGraphics[domain,"Klein"];
Print["Preparing notebook."];
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
 Cell["Evaluate the following cell with this notebook in the outputs directory.","Text"],
 Cell[BoxData[ToBoxes[Defer[Get[FileNameJoin[{ParentDirectory[NotebookDirectory[]],"Run14n12345.wl"}]]]]],"Input"]
 },WindowTitle->"K14n12345 — Wolfram",StyleDefinitions->"Default.nb"];
Print["Writing notebook."];
Put[nb,FileNameJoin[{out,"14n12345-Wolfram.nb"}]];
Export[FileNameJoin[{out,"domain-preview.png"}],GraphicsRow[{pg,kg},ImageSize->1400],"PNG"];
Print["Saved results.json, notebook, and preview."];
