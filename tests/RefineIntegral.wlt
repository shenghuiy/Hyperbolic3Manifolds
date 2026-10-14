(* Re-integrate the saved K14n12345 domain and compare with the saved results. *)
root=ParentDirectory[DirectoryName[$InputFileName]];Get[FileNameJoin[{root,"src","Hyperbolic3Manifolds.wl"}]];
out=FileNameJoin[{root,"outputs"}];
d=Import[FileNameJoin[{out,"domain.wxf"}],"WXF"];
s=Import[FileNameJoin[{out,"structure.wxf"}],"WXF"];
saved=Import[FileNameJoin[{out,"domain-integral.wxf"}],"WXF"];
VerificationTest[AssociationQ[d]&&AssociationQ[s]&&AssociationQ[saved],True,TestID->"Load saved domain, structure, integral"]
i=If[AssociationQ[d],IntegrateDomainVolume[d,10],$Failed];
VerificationTest[AssociationQ[i]&&Abs[i["Volume"]-s["Volume"]]<10^-7,True,TestID->"Re-integration agrees with tetrahedral volume"]
VerificationTest[AssociationQ[i]&&Abs[i["Volume"]-saved["Volume"]]<10^-12,True,TestID->"Re-integration reproduces saved integral"]
