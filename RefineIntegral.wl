root=DirectoryName[$InputFileName];Get[FileNameJoin[{root,"src","Hyperbolic3Manifolds.wl"}]];
out=FileNameJoin[{root,"outputs"}];
d=Import[FileNameJoin[{out,"domain.wxf"}],"WXF"];
s=Import[FileNameJoin[{out,"structure.wxf"}],"WXF"];
i=IntegrateDomainVolume[d,10];
Print["Refined integral: ",i["Volume"],"; difference: ",N[i["Volume"]-s["Volume"]]];
Export[FileNameJoin[{out,"domain-integral.wxf"}],i,"WXF"];
