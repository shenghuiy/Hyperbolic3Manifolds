(* Drive the Hyperbolic3Manifolds pipeline on one triangulation from the command line.
   Run with an ABSOLUTE script path:
     WolframKernel -script /abs/.claude/skills/run-hyperbolic3manifolds/driver.wl <source> [options]
   <source> is one of:
     sig <isosig>                  an isomorphism signature, e.g. cPcbbbiht
     knot <Name> --csv <path>      a row of the pinned knot CSV, e.g. K6a1
     record <path.json>            a record like data/14n12345-record.json
   Options:
     --stop solve|holonomy|domain|integral   last stage to run (default integral)
     --out <dir>                   write summary.json, poincare.png, klein.png there
     --wp <n> --goal <n>           solver working precision / precision goal (default 120 45)
     --igoal <n>                   domain-integral precision goal (default 10, as in the tests)
   Prints one line per stage and a final JSON summary; exits 1 if any stage fails. *)
root=FileNameJoin[Drop[FileNameSplit[DirectoryName[$InputFileName]],-3]];
Get[FileNameJoin[{root,"src","Hyperbolic3Manifolds.wl"}]];

args=Which[Length[$ScriptCommandLine]>1,Rest[$ScriptCommandLine],
 MemberQ[$CommandLine,"-script"],Drop[$CommandLine,First[FirstPosition[$CommandLine,"-script"]]+1],True,{}];
opt[name_,default_]:=With[{p=FirstPosition[args,name]},If[MissingQ[p]||p[[1]]==Length[args],default,args[[p[[1]]+1]]]];
fail[msg__]:=(Print["ERROR: ",msg];Exit[1]);
If[Length[args]<2,fail["usage: driver.wl sig <isosig> | knot <Name> --csv <path> | record <file.json> [--stop stage] [--out dir]"]];

(* Same narrow reader as the README: split on commas, refuse quoted rows. *)
findKnot[file_,name_]:=Module[{s=OpenRead[file],keys,line,row=Missing["NotFound"]},
 keys=StringSplit[ReadLine[s],","];
 While[(line=ReadLine[s])=!=EndOfFile,
  If[StringContainsQ[line,","<>name<>","],
   If[StringContainsQ[line,"\""],Close[s];fail["quoted CSV row for ",name]];
   row=AssociationThread[keys,StringSplit[line,","]];Break[]]];
 Close[s];row];

record=Switch[args[[1]],
 "sig",<|"name"->args[[2]],"triangulation"->args[[2]]|>,
 "knot",With[{csv=opt["--csv",FileNameJoin[{root,"data","knots_and_links_through_14.csv"}]]},
  If[!FileExistsQ[csv],fail["CSV not found: ",csv]];findKnot[csv,args[[2]]]],
 "record",Import[args[[2]],"RawJSON"],
 _,fail["unknown source ",args[[1]]]];
If[!AssociationQ[record],fail["record not found: ",args[[2]]]];

stages={"solve","holonomy","domain","integral"};
stop=opt["--stop","integral"];If[!MemberQ[stages,stop],fail["--stop must be one of ",stages]];
upTo[s_]:=LessEqual@@Flatten[Position[stages,#]&/@{s,stop}];
wp=ToExpression[opt["--wp","120"]];igoal=ToExpression[opt["--igoal","10"]];goal=ToExpression[opt["--goal","45"]];
out=opt["--out",None];
(* Volumes as plain decimal strings; residuals keep InputForm so an exact-zero
   high-precision residual shows its accuracy, e.g. 0``52.1, instead of 0.0. *)
num[x_,n_]:=ToString[N[x,n],InputForm,NumberMarks->False];
res[x_]:=If[x==0,"0 (to 10^-"<>ToString[Floor[Accuracy[x]]]<>")",
 With[{me=MantissaExponent[N[x]]},ToString[Round[10 me[[1]],0.01]]<>"e"<>ToString[me[[2]]-1]]];
secs[t_]:=ToString[NumberForm[t,{6,1}]]<>" s";
summary=<|"Name"->record["name"],"Signature"->record["triangulation"]|>;
check[x_,stage_]:=If[FailureQ[x]||!AssociationQ[x],
 Print[stage,": FAILED ",x];summary["FailedStage"]=stage;summary["Failure"]=ToString[x,InputForm];
 Print[ExportString[summary,"RawJSON"]];Exit[1],x];

t=check[DecodeTriangulation[record["triangulation"]],"decode"];
top=check[ValidateIdealTriangulation[t],"validate"];
Print["decode: ",t["Tetrahedra"]," tetrahedra; cusps ",top["Cusps"],", link Euler characteristics ",top["VertexLinkEulerCharacteristics"]];
summary=Join[summary,<|"Tetrahedra"->t["Tetrahedra"],"Cusps"->top["Cusps"]|>];

{time,s}=AbsoluteTiming[check[SolveCompleteStructure[t,wp,goal],"solve"]];
summary=Join[summary,<|"Volume"->num[s["Volume"],40],
 "AngleEquationResidual"->res[s["AngleEquationResidual"]],"GradientResidual"->res[s["GradientResidual"]],
 "ComplexEdgeResidual"->res[s["ComplexEdgeResidual"]]|>];
If[KeyExistsQ[record,"volume"],summary["DatasetVolume"]=record["volume"]];
Print["solve: volume ",num[s["Volume"],30]," (",secs[time],")"];

If[upTo["holonomy"],
 h=check[BuildHolonomy[t,s],"holonomy"];
 summary["Generators"]=Length[h["Generators"]];Print["holonomy: ",Length[h["Generators"]]," generators"]];
If[upTo["domain"],
 {time,d}=AbsoluteTiming[check[BuildDirichletDomain[h],"domain"]];
 summary=Join[summary,<|"DomainVEF"->(Length/@Lookup[d,{"Vertices","Edges","Faces"}]),
  "PairingVertexResidual"->d["PairingVertexResidual"],"EdgeCycleAngleResidual"->d["EdgeCycleAngleResidual"]|>];
 Print["domain: V,E,F = ",summary["DomainVEF"]," (",secs[time],")"]];
If[upTo["integral"],
 i=check[IntegrateDomainVolume[d,igoal],"integral"];
 summary["IntegralDifference"]=N[i["Volume"]-s["Volume"]];Print["integral: domain - tetrahedral = ",summary["IntegralDifference"]]];

If[StringQ[out],
 If[!DirectoryQ[out],CreateDirectory[out,CreateIntermediateDirectories->True]];
 Export[FileNameJoin[{out,"summary.json"}],summary,"RawJSON"];
 If[upTo["domain"],
  Export[FileNameJoin[{out,"poincare.png"}],DomainGraphics[d,"Poincare"],"PNG",ImageSize->800];
  Export[FileNameJoin[{out,"klein.png"}],DomainGraphics[d,"Klein"],"PNG",ImageSize->800]];
 Print["wrote ",out]];
Print[ExportString[summary,"RawJSON"]];
