root=DirectoryName[$InputFileName];
report=TestReport[FileNameJoin[{root,"Hyperbolic3Manifolds.wlt"}]];
summary=<|"Succeeded"->report["TestsSucceededCount"],"Failed"->report["TestsFailedCount"]|>;
Export[FileNameJoin[{root,"outputs","tests.json"}],summary,"RawJSON"];
Print[summary];
If[report["TestsFailedCount"]>0,Print[report["TestsFailed"]];Exit[1]];
