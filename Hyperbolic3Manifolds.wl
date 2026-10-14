(* Continued from the shared ChatGPT implementation. Pure Wolfram Language.
   Numerical diagnostics are not interval-certified existence proofs. *)
BeginPackage["Hyperbolic3Manifolds`"];
DecodeTriangulation::usage="DecodeTriangulation[s] decodes a connected classic 3D isomorphism signature with paired faces.";
AngleSystem::usage="AngleSystem[t] constructs exact angle constraints.";
ValidateIdealTriangulation::usage="ValidateIdealTriangulation[t] checks edge reversals and computes every ideal vertex link Euler characteristic.";
SolveCompleteStructure::usage="SolveCompleteStructure[t,wp,goal] seeks an interior stationary point of volume.";
BuildHolonomy::usage="BuildHolonomy[t,s] develops tetrahedra and constructs PSL(2,C) generators.";
BuildDirichletDomain::usage="BuildDirichletDomain[h,maxIterations] constructs and numerically checks a candidate Dirichlet domain.";
IntegrateDomainVolume::usage="IntegrateDomainVolume[d,goal] integrates hyperbolic volume through a boundary flux integral.";
DomainGraphics::usage="DomainGraphics[d,model] draws a domain in the Poincare or Klein ball.";
Begin["`Private`"];
assert[c_,tag_,details_:<||>]:=If[!TrueQ[c],Throw[Failure[tag,details]]];
DecodeTriangulation[s_String]:=Catch@Module[
 {parts,codes,alphabet,n,width=1,pos=2,readInt,actions={},used=0,block,m,dests,perms,
 table,next=1,ai=1,ji=1,j,p,kind,records,ori},
 parts=StringSplit[s,"_"];alphabet=Characters["abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789+-"];
 assert[Length[parts]>0,"EmptySignature"];
 assert[And@@(MemberQ[alphabet,#]& /@ Characters[First[parts]]),"InvalidAlphabet"];
 codes=(First[FirstPosition[alphabet,#]]-1& /@ Characters[First[parts]]);
 n=First[codes];
 readInt[w_]:=Module[{v},assert[w>0&&pos+w-1<=Length[codes],"TruncatedSignature"];
 v=codes[[pos;;pos+w-1]].(64^Range[0,w-1]);pos+=w;v];
 If[n==63,width=readInt[1];n=readInt[width]];
 assert[n>0&&IntegerQ[n],"EmptyTriangulation"];
 While[used<4 n,block=Reverse[IntegerDigits[readInt[1],4,3]];
 Do[If[used<4 n,assert[a<=2,"InvalidFacetAction"];AppendTo[actions,a];used+=If[a==0,1,2],
 assert[a==0,"InvalidPadding"]],{a,block}]];
 assert[used==4 n,"FacetCountMismatch"];
 assert[FreeQ[actions,0],"BoundaryFacesUnsupported"];
 m=Count[actions,2];dests=Table[readInt[width],{m}];
 perms=Table[readInt[1],{m}];assert[pos==Length[codes]+1,"TrailingSignatureData"];
 assert[And@@(0<=#<n& /@ dests)&&And@@(0<=#<24& /@ perms),"InvalidGluingIndex"];
 perms=Sort[Permutations[Range[0,3]]][[perms+1]];
 table=ConstantArray[Null,{n,4}];
 Do[If[table[[t+1,f+1]]===Null,
 assert[ai<=Length[actions],"MissingFacetAction"];kind=actions[[ai++]];
 If[kind==1,j=next++;p=Range[0,3],assert[ji<=m,"MissingJoin"];j=dests[[ji]];p=perms[[ji++]]];
 assert[0<=j<n,"InvalidDestination"];
 assert[table[[j+1,p[[f+1]]+1]]===Null,"InvalidFacePair"];
 assert[!(j==t&&p[[f+1]]==f),"SelfPairedFace"];
 table[[t+1,f+1]]={j,p};table[[j+1,p[[f+1]]+1]]={t,Ordering[p]-1}],
 {t,0,n-1},{f,0,3}];
 assert[next==n&&ai==Length[actions]+1&&ji==m+1,"DisconnectedOrMalformed"];
 records=Flatten[Table[<|"tetrahedron"->t,"face"->f,"neighbor"->table[[t+1,f+1,1]],
 "vertex_permutation"->table[[t+1,f+1,2]]|>,{t,0,n-1},{f,0,3}],1];
 ori=ConstantArray[0,n];ori[[1]]=1;
 Do[Do[If[ori[[r["tetrahedron"]+1]]!=0,
 j=r["neighbor"]+1;p=-Signature[r["vertex_permutation"]] ori[[r["tetrahedron"]+1]];
 assert[ori[[j]]==0||ori[[j]]==p,"NonOrientableTriangulation"];ori[[j]]=p],{r,records}],{n}];
 <|"Signature"->s,"Tetrahedra"->n,"FacePairings"->records,"Orientations"->ori,
 "PeripheralDecoration"->If[Length[parts]>1,parts[[2]],None]|>
];
ValidateIdealTriangulation[t_Association]:=Catch@Module[
 {n=t["Tetrahedra"],fp=t["FacePairings"],pairs,vid,eid,cg,eg,sg,cusps,corners,sides,labels,chi},
 pairs=Select[Tuples[Range[0,3],2],Unequal@@#&];
 vid[j_,v_]:=4 j+v+1;
 eid[j_,v_,u_]:=12 j+First[FirstPosition[pairs,{v,u}]];
 cg=Graph[Range[4 n],Flatten[Table[With[{j=r["tetrahedron"],k=r["neighbor"],p=r["vertex_permutation"],f=r["face"]},
 Table[UndirectedEdge[vid[j,v],vid[k,p[[v+1]]]],{v,DeleteCases[Range[0,3],f]}]],{r,fp}]]];
 eg=Graph[Range[12 n],Flatten[Table[With[{j=r["tetrahedron"],k=r["neighbor"],p=r["vertex_permutation"],f=r["face"]},
 Table[UndirectedEdge[eid[j,a[[1]],a[[2]]],eid[k,p[[a[[1]]+1]],p[[a[[2]]+1]]]],{a,Select[pairs,FreeQ[#,f]&]}]],{r,fp}]]];
 sg=Graph[Range[12 n],Flatten[Table[With[{j=r["tetrahedron"],k=r["neighbor"],p=r["vertex_permutation"],f=r["face"]},
 Table[UndirectedEdge[eid[j,v,f],eid[k,p[[v+1]],p[[f+1]]]],{v,DeleteCases[Range[0,3],f]}]],{r,fp}]]];
 cusps=ConnectedComponents[cg];corners=ConnectedComponents[eg];sides=ConnectedComponents[sg];
 labels=Association[Flatten[MapIndexed[Thread[#1->First[#2]]&,corners]]];
 assert[And@@Flatten[Table[labels[eid[j,a[[1]],a[[2]]]]!=labels[eid[j,a[[2]],a[[1]]]],{j,0,n-1},{a,pairs}]],"ReversedEdge"];
 chi=Table[Count[corners,c_/;MemberQ[cusp,vid[Quotient[First[c]-1,12],pairs[[Mod[First[c]-1,12]+1,1]]]]] -
 Count[sides,c_/;MemberQ[cusp,vid[Quotient[First[c]-1,12],pairs[[Mod[First[c]-1,12]+1,1]]]]] + Length[cusp],{cusp,cusps}];
 assert[And@@(#==0& /@ chi),"NonTorusVertexLinks",<|"EulerCharacteristics"->chi|>];
 <|"Cusps"->Length[cusps],"VertexLinkEulerCharacteristics"->chi,"ReversedEdges"->False|>
];
AngleSystem[t_Association]:=Module[{n=t["Tetrahedra"],edges,edgeID,graph,classes,typ,ae,at,a,b},
 edges=Subsets[Range[0,3],{2}];
 edgeID[j_,e_]:=6 j+First[FirstPosition[edges,Sort[e]]];
 graph=Graph[Range[6 n],Flatten[Table[With[{j=r["tetrahedron"],k=r["neighbor"],
 p=r["vertex_permutation"],f=r["face"]},
 UndirectedEdge[edgeID[j,#],edgeID[k,p[[#+1]]]]& /@
 Subsets[DeleteCases[Range[0,3],f],{2}]],{r,t["FacePairings"]}]]];
 classes=ConnectedComponents[graph];typ={1,2,3,3,2,1};
 ae=Table[Normal[SparseArray[Rule@@@Normal[Counts[
 (3 Quotient[#-1,6]+typ[[Mod[#-1,6]+1]])& /@ c]],3 n]],{c,classes}];
 at=KroneckerProduct[IdentityMatrix[n],{{1,1,1}}];a=Join[at,ae];
 b=Join[ConstantArray[1,n],ConstantArray[2,Length[classes]]];
 <|"Matrix"->a,"RightHandSideInPiUnits"->b,"EdgeMatrix"->ae,
 "EdgeClasses"->classes,"NullSpace"->NullSpace[a]|>
];
lobVolume[v_]:=Total[Im[PolyLog[2,Exp[2 I #]]]/2& /@ v];
SolveCompleteStructure[t_Association,wp_Integer:120,goal_Integer:45]:=Catch@Module[
 {sys,n=t["Tetrahedra"],a,b,vars,h,lin,theta,bn,grad,hess,step,delta,rate,old,
 history={},res=Infinity,ang,z,signed,logs,edgeResidual,volume,bw,integral},
 assert[goal>0&&wp>=2 goal+20,"InsufficientWorkingPrecision"];
 With[{validation=ValidateIdealTriangulation[t]},If[FailureQ[validation],Throw[validation]]];
 sys=AngleSystem[t];a=sys["Matrix"];b=sys["RightHandSideInPiUnits"];
 vars=Array[Unique["angle"]&,3 n];h=Unique["margin"];
 lin=LinearOptimization[-h,Join[Thread[a.vars==b],Thread[vars>=h],{h>=0}],
 Append[vars,h],"PrimalMinimizer"];
 assert[VectorQ[lin,NumericQ]&&Last[lin]>0,"NoStrictAngleStructure"];
 theta=N[Pi Most[lin],wp];bn=N[sys["NullSpace"],wp];
 Do[grad=-bn.Log[2 Sin[theta]];res=Max[Abs[grad]];
 If[TrueQ[res<10^-goal],Break[]];
 hess=-bn.DiagonalMatrix[Cot[theta]].Transpose[bn];
 step=-LinearSolve[hess,grad];delta=step.bn;rate=1;old=lobVolume[theta];
 While[Min[theta+rate delta]<=0||Max[theta+rate delta]>=Pi||
 lobVolume[theta+rate delta]<old+rate grad.step/10000,
 rate/=2;assert[rate>2^-100,"NewtonLineSearchFailed"]];
 theta=SetPrecision[theta+rate delta,wp];
 AppendTo[history,<|"Iteration"->iter,"Volume"->lobVolume[theta],
 "GradientResidualBeforeStep"->res,"StepFraction"->rate|>],{iter,80}];
 res=Max[Abs[-bn.Log[2 Sin[theta]]]];
 assert[TrueQ[res<10^-goal],"NoInteriorCriticalPoint",<|"Residual"->res|>];
 ang=Partition[theta,3];
 z=Sin[#[[2]]]/Sin[#[[3]]] Exp[I #[[1]]]& /@ ang;
 signed=MapThread[If[#2==1,#1,Conjugate[#1]]&,{z,t["Orientations"]}];
 logs=Flatten[MapThread[#2 {Log[#1],Log[1/(1-#1)],Log[(#1-1)/#1]}&,
 {signed,t["Orientations"]}]];
 edgeResidual=Max[Abs[Exp[sys["EdgeMatrix"].logs]-1]];
 assert[edgeResidual<10^(-goal+5),"ComplexEdgeEquationsFailed"];
 volume=lobVolume[theta];bw=Total[Im[PolyLog[2,#]]+Arg[1-#] Log[Abs[#]]& /@ z];
 integral=Total[Table[-NIntegrate[Log[2 Sin[u]],{u,0,th},WorkingPrecision->wp,
 AccuracyGoal->goal,PrecisionGoal->goal,Method->{"GlobalAdaptive","SymbolicProcessing"->0}],{th,theta}]];
 <|"Angles"->theta,"UnsignedShapes"->z,"ShapesInOriginalLabels"->signed,
 "Volume"->volume,"BlochWignerVolume"->bw,"QuadratureVolume"->integral,
 "GradientResidual"->res,"AngleEquationResidual"->Max[Abs[a.theta-Pi b]],
 "ComplexEdgeResidual"->edgeResidual,"MinimumAngle"->Min[theta],
 "WorkingPrecision"->wp,"RequestedGoal"->goal,"History"->history,"AngleSystem"->sys|>
];
tripleMap[src_,dst_]:=Module[{rows,h},
 rows=MapThread[Function[{u,v},{v[[2]] u[[1]],v[[2]] u[[2]],-v[[1]] u[[1]],-v[[1]] u[[2]]}],{src,dst}];
 h=Partition[First[NullSpace[rows]],2];h/Sqrt[Det[h]]];
BuildHolonomy[t_Association,s_Association]:=Module[
 {n=t["Tetrahedra"],fp=t["FacePairings"],pts,trans,dev,gen,c,j,k,f,p,v},
 pts=({{1,0},{0,1},{1,1},{#,1}}& /@ s["ShapesInOriginalLabels"]);
 trans=Table[j=r["tetrahedron"]+1;k=r["neighbor"]+1;f=r["face"]+1;
 p=r["vertex_permutation"]+1;v=DeleteCases[Range[4],f];
 tripleMap[pts[[k,p[[v]]]],pts[[j,v]]],{r,fp}];
 dev=ConstantArray[0,n];dev[[1]]=IdentityMatrix[2];
 Do[Do[j=fp[[i]]["tetrahedron"]+1;k=fp[[i]]["neighbor"]+1;
 If[MatrixQ[dev[[j]]]&&!MatrixQ[dev[[k]]],dev[[k]]=dev[[j]].trans[[i]]],{i,Length[fp]}],{n}];
 gen=Table[j=fp[[i]]["tetrahedron"]+1;k=fp[[i]]["neighbor"]+1;
 dev[[j]].trans[[i]].Inverse[dev[[k]]],{i,Length[fp]}];
 c={{1,-(1/2+I/3)},{0,1}};gen=(c.#.Inverse[c]& /@ gen);
 gen=Select[gen,Norm[#-Tr[#]/2 IdentityMatrix[2]]>10^-20&];
 gen=DeleteDuplicates[gen,Min[Norm[#1-#2],Norm[#1+#2]]<10^-20&];
 <|"Generators"->gen,"DevelopingMaps"->dev,"FaceTransitions"->trans,
 "BasepointUpperHalfSpace"->{1/2,1/3,1}|>
];
orbit[g_]:=Module[{m=g.ConjugateTranspose[g]},
 Re[{Tr[m]/2,m[[1,2]],-I m[[1,2]],(m[[1,1]]-m[[2,2]])/2}]];
bisectorNormal[g_]:=With[{o=orbit[g]},Rest[o]/(First[o]-1)];
kleinAction[g_,v_]:=Module[{m=g.{{1+v[[3]],v[[1]]+I v[[2]]},
 {v[[1]]-I v[[2]],1-v[[3]]}}.ConjugateTranspose[g]},
 Re[{2 m[[1,2]],-2 I m[[1,2]],m[[1,1]]-m[[2,2]]}/Tr[m]]];
BuildDirichletDomain[h_Association,maxIterations_Integer:12]:=Catch@Module[
 {pool=N[h["Generators"]],normals,hull,active,coords,near,ids,vertices,candidates,
 history={},stable=False,faces,pts,ctr,u,v,edges,links={},edgeClasses,angles,
 residual,pairResidual,facePairs,fe,ei,ej,mapped,ff,n1,n2,invNormals},
 Do[normals=bisectorNormal /@ pool;hull=ConvexHullMesh[normals];
 active=DeleteDuplicates[Flatten[MeshCells[hull,2][[All,1]]]];
 coords=MeshCoordinates[hull];near=Nearest[normals->"Index"];
 ids=(First[near[#]]& /@ coords[[active]]);pool=pool[[ids]];
 normals=bisectorNormal /@ pool;hull=ConvexHullMesh[normals];coords=MeshCoordinates[hull];
 vertices=DeleteDuplicates[Table[Quiet[LinearSolve[coords[[Take[face[[1]],3]]],{1.,1.,1.}]],
 {face,MeshCells[hull,2]}],Norm[#1-#2]<10^-7&];
 assert[MatrixQ[vertices,NumericQ],"DegeneratePolarHull"];
 candidates=Join[pool,Flatten[Table[a.b,{a,pool},{b,pool}],1]];
 candidates=Select[candidates,Norm[#-Tr[#]/2 IdentityMatrix[2]]>10^-7&];
 candidates=DeleteDuplicatesBy[candidates,Round[bisectorNormal[#],10^-7]&];
 candidates=Select[candidates,Max[vertices.bisectorNormal[#]]>1+10^-8&];
 AppendTo[history,<|"Iteration"->iter,"Faces"->Length[pool],
 "Vertices"->Length[vertices],"NewCuts"->Length[candidates]|>];
 If[Length[candidates]==0,stable=True;Break[]];pool=Join[pool,candidates],{iter,maxIterations}];
 assert[stable,"DomainDidNotStabilize"];
 assert[Max[Norm /@ vertices]<1+10^-7,"DomainExtendsOutsideBall"];
 assert[Max[Flatten[vertices.Transpose[normals]]]<1+10^-7,"HalfSpaceViolation"];
 faces=Table[ids=Flatten[Position[Abs[vertices.q-1],x_/;x<10^-7]];
 assert[Length[ids]>=3,"DegenerateFace"];pts=vertices[[ids]];ctr=Mean[pts];
 u=Normalize[First[pts]-ctr];v=Normalize[Cross[q,u]];
 ids[[Ordering[ArcTan[(#-ctr).u,(#-ctr).v]& /@ pts]]],{q,normals}];
 edges=DeleteDuplicates[Sort /@ Flatten[(Partition[Append[#,First[#]],2,1]& /@ faces),1]];
 assert[Length[vertices]-Length[edges]+Length[faces]==2,"PolyhedronEulerCheckFailed"];
 near=Nearest[vertices->"Index"];pairResidual=0.;
 invNormals=bisectorNormal /@ (Inverse /@ pool);
 facePairs=(First[Nearest[normals->"Index",#]]& /@ invNormals);
 assert[Max[Norm /@ (invNormals-normals[[facePairs]])]<10^-7,"MissingInverseFace"];
 Do[mapped=kleinAction[Inverse[pool[[i]]],#]& /@ vertices[[faces[[i]]]];
 ids=First[near[#]]& /@ mapped;
 pairResidual=Max[pairResidual,Max[Norm /@ (mapped-vertices[[ids]])]];
 assert[Sort[ids]==Sort[faces[[facePairs[[i]]]]],"FacePairingMismatch"];
 fe=Partition[Append[faces[[i]],First[faces[[i]]]],2,1];
 Do[ei=First[FirstPosition[edges,Sort[ee]]];
 mapped=Sort[First[near[kleinAction[Inverse[pool[[i]]],vertices[[#]]]]]& /@ ee];
 ej=First[FirstPosition[edges,mapped]];AppendTo[links,UndirectedEdge[ei,ej]],{ee,fe}],
 {i,Length[faces]}];
 assert[pairResidual<10^-7,"PairingVertexResidualTooLarge"];
 edgeClasses=ConnectedComponents[Graph[Range[Length[edges]],links]];
 angles=Table[ff=Select[Range[Length[faces]],SubsetQ[faces[[#]],ee]&];
 assert[Length[ff]==2,"InvalidPolyhedronEdge"];{n1,n2}=normals[[ff]];
 ArcCos[Clip[(1-n1.n2)/Sqrt[(n1.n1-1)(n2.n2-1)],{-1,1}]],{ee,edges}];
 residual=Max[Abs[(Total[angles[[#]]]& /@ edgeClasses)-2 Pi]];
 assert[residual<10^-7,"EdgeCycleAngleCheckFailed"];
 <|"Vertices"->vertices,"Normals"->normals,"Faces"->faces,"Edges"->edges,
 "Generators"->pool,"FacePairs"->facePairs,"EdgeClasses"->edgeClasses,
 "PairingVertexResidual"->pairResidual,"EdgeCycleAngleResidual"->residual,
 "IdealVertices"->Flatten[Position[Norm /@ vertices,x_/;Abs[x-1]<10^-7]],
 "History"->history,"Status"->"Numerically checked candidate; not certified"|>
];
IntegrateDomainVolume[d_Association,goal_Integer:8]:=Module[
 {verts=d["Vertices"],tri,aa,bb,cc,jac,fun,values},
 tri=Flatten[Table[Table[{Mean[verts[[f]]],verts[[f[[i]]]],
 verts[[f[[Mod[i,Length[f]]+1]]]]},{i,Length[f]}],{f,d["Faces"]}],1];
 values=Table[{aa,bb,cc}=SetPrecision[t,30];
 If[Abs[bb.bb-1]<10^-7,bb=Normalize[bb]];
 If[Abs[cc.cc-1]<10^-7,cc=Normalize[cc]];
 jac=Abs[Det[{aa,bb-aa,cc-aa}]];
 fun[u_?NumericQ,w_?NumericQ]:=Module[{r=Norm[aa+u (bb-aa)+(1-u) w (cc-aa)]},
 jac (1-u) (r/(1-r^2)-ArcTanh[r])/(2 r^3)];
 NIntegrate[fun[u,w],{u,0,1},{w,0,1},WorkingPrecision->30,
 AccuracyGoal->goal,PrecisionGoal->goal,MaxRecursion->20,
 Method->{"GlobalAdaptive","SymbolicProcessing"->0}],{t,tri}];
 <|"Volume"->Total[values],"Triangles"->Length[tri],"PerTriangleGoal"->goal,
 "GeometryPrecision"->"Machine precision","TriangleIntegrals"->values|>
];
toPoincare[k_]:=k/(1+Sqrt[Max[0,1-k.k]]);
subdivide[{a_,b_,c_},0]:={{a,b,c}};
subdivide[{a_,b_,c_},n_]:=Join@@(subdivide[#,n-1]& /@
 {{a,(a+b)/2,(a+c)/2},{b,(b+c)/2,(a+b)/2},
 {c,(a+c)/2,(b+c)/2},{(a+b)/2,(b+c)/2,(a+c)/2}});
DomainGraphics[d_Association,model_String:"Poincare"]:=Module[
 {verts=d["Vertices"],map,polys,curves,ideal},
 map=If[model=="Klein",Identity,toPoincare];
 polys=Flatten[Table[Flatten[Table[subdivide[{Mean[verts[[f]]],verts[[f[[i]]]],
 verts[[f[[Mod[i,Length[f]]+1]]]]},2],{i,Length[f]}],1],{f,d["Faces"]}],1];
 curves=Table[Line[map /@ Table[(1-u) verts[[e[[1]]]]+u verts[[e[[2]]]],{u,0,1,1/24}]],{e,d["Edges"]}];
 ideal=map /@ verts[[d["IdealVertices"]]];
 Graphics3D[{{Opacity[.32],RGBColor[.15,.55,.82],EdgeForm[None],Polygon[map /@ #]& /@ polys},
 {RGBColor[.12,.25,.4],AbsoluteThickness[1],curves},
 {RGBColor[.95,.4,.15],PointSize[.02],Point[ideal]},
 {Gray,PointSize[.012],Point[{0,0,0}]}},Boxed->False,Lighting->"Neutral",
 PlotRange->{{-1,1},{-1,1},{-1,1}},ImageSize->600,SphericalRegion->True,
 PlotLabel->Row[{"Dirichlet domain — ",model," model"}]]
];
End[];
EndPackage[];
