(* Full K14n12345 pipeline. Writes outputs/*.wxf used by the later suites. *)
root=ParentDirectory[DirectoryName[$InputFileName]];
Get[FileNameJoin[{root,"src","Hyperbolic3Manifolds.wl"}]];
out=FileNameJoin[{root,"outputs"}];If[!DirectoryQ[out],CreateDirectory[out]];
record=Import[FileNameJoin[{root,"data","14n12345-record.json"}],"RawJSON"];
VerificationTest[AssociationQ[record],True,TestID->"Load K14n12345 record"]
tri=If[AssociationQ[record],DecodeTriangulation[record["triangulation"]],$Failed];
VerificationTest[AssociationQ[tri]&&tri["Tetrahedra"]==20,True,TestID->"Decode signature"]
If[AssociationQ[tri],Export[FileNameJoin[{out,"face-pairings.json"}],tri,"RawJSON"]];
structure=If[AssociationQ[tri],SolveCompleteStructure[tri,120,45],$Failed];
VerificationTest[AssociationQ[structure],True,TestID->"Solve complete structure"]
If[AssociationQ[structure],Export[FileNameJoin[{out,"structure.wxf"}],structure,"WXF"]];
VerificationTest[AssociationQ[structure]&&Abs[structure["Volume"]-record["volume"]]<10^-8,True,
 TestID->"Volume agrees with rounded database reference"]
holonomy=If[AssociationQ[structure],BuildHolonomy[tri,structure],$Failed];
VerificationTest[AssociationQ[holonomy]&&Length[holonomy["Generators"]]>0,True,TestID->"Build holonomy"]
If[AssociationQ[holonomy],Export[FileNameJoin[{out,"holonomy.wxf"}],holonomy,"WXF"]];
domain=If[AssociationQ[holonomy],BuildDirichletDomain[holonomy],$Failed];
VerificationTest[AssociationQ[domain],True,TestID->"Build Dirichlet domain"]
If[AssociationQ[domain],Export[FileNameJoin[{out,"domain.wxf"}],domain,"WXF"]];
VerificationTest[Length /@ Lookup[domain,{"Vertices","Edges","Faces"}],{161,243,84},TestID->"Domain V,E,F"]
integral=If[AssociationQ[domain],IntegrateDomainVolume[domain,10],$Failed];
VerificationTest[AssociationQ[integral]&&Abs[integral["Volume"]-structure["Volume"]]<10^-7,True,
 TestID->"Domain integral agrees with tetrahedral volume"]
If[AssociationQ[integral],Export[FileNameJoin[{out,"domain-integral.wxf"}],integral,"WXF"]];
