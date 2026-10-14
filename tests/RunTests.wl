(* Runs the test suites in dependency order: Run14n12345 writes outputs/*.wxf,
   which RefineIntegral, MakeReport, and Hyperbolic3Manifolds read.
   ImportDataset runs only when the 32 MB CSV is present in data/.
   Pass suite names as arguments to run a subset, e.g. RunTests.wl Hyperbolic3Manifolds *)
root=ParentDirectory[DirectoryName[$InputFileName]];
suites={"ImportDataset","Run14n12345","RefineIntegral","MakeReport","Hyperbolic3Manifolds"};
(* wolframscript fills $ScriptCommandLine; WolframKernel -script leaves it empty, so read $CommandLine. *)
requested=Which[Length[$ScriptCommandLine]>1,Rest[$ScriptCommandLine],
 MemberQ[$CommandLine,"-script"],Drop[$CommandLine,First[FirstPosition[$CommandLine,"-script"]]+1],True,{}];
If[requested=!={},
 If[!SubsetQ[suites,requested],Print["Unknown suites: ",Complement[requested,suites]];Exit[1]];
 suites=Select[suites,MemberQ[requested,#]&]];
If[MemberQ[suites,"ImportDataset"]&&!FileExistsQ[FileNameJoin[{root,"data","knots_and_links_through_14.csv"}]],
 Print["Skipping ImportDataset: data/knots_and_links_through_14.csv not present (see data/README.md)."];
 suites=DeleteCases[suites,"ImportDataset"]];
results=Association[Table[
 Print["Running ",name];
 report=TestReport[FileNameJoin[{root,"tests",name<>".wlt"}],ProgressReporting->False];
 Print["  ",report["TestsSucceededCount"]," succeeded, ",report["TestsFailedCount"]," failed"];
 If[report["TestsFailedCount"]>0,Print["  Failed: ",#["TestID"]& /@ Select[Values[report["TestResults"]],#["Outcome"]=!="Success"&]]];
 name-><|"Succeeded"->report["TestsSucceededCount"],"Failed"->report["TestsFailedCount"]|>,{name,suites}]];
summary=<|"Succeeded"->Total[results[[All,"Succeeded"]]],"Failed"->Total[results[[All,"Failed"]]],"Suites"->results|>;
Export[FileNameJoin[{root,"outputs","tests.json"}],summary,"RawJSON"];
Print[summary];
If[summary["Failed"]>0||summary["Succeeded"]==0,Exit[1]];
