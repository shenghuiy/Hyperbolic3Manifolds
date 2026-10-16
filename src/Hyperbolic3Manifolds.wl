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
(* {tetrahedron, neighbor, vertex_permutation, face} for every face pairing *)
gluings[fp_]:=Lookup[fp,{"tetrahedron","neighbor","vertex_permutation","face"}];
(* Graph on cells glued across faces: cells[f] lists the cells of face f, id[j,c] numbers cell c of tetrahedron j *)
gluingGraph[size_,fp_,id_,cells_]:=Graph[Range[size],Catenate[
 Function[{j,k,p,f},UndirectedEdge[id[j,#],id[k,p[[#+1]]]]& /@ cells[f]]@@@gluings[fp]]];
componentLabels[comps_]:=Association[Catenate[MapIndexed[Thread[#1->First[#2]]&,comps]]];
cyclicPairs[l_]:=Partition[l,2,1,1];
nontrivialQ[g_,tol_]:=Norm[g-Tr[g]/2 IdentityMatrix[2]]>tol;
DecodeTriangulation[s_String]:=Catch@Module[
 {parts=StringSplit[s,"_"],codes,read,n,width,pos,addAction,actions,used,m,dests,perms,
 glue,table,ai,next,ji,records,orient},
 assert[Length[parts]>0,"EmptySignature"];
 codes=Lookup[AssociationThread[Characters[
  "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789+-"],Range[0,63]],Characters[First[parts]]];
 assert[FreeQ[codes,_Missing],"InvalidAlphabet"];
 read[p_,w_]:=(assert[w>0&&p+w-1<=Length[codes],"TruncatedSignature"];FromDigits[Reverse[codes[[p;;p+w-1]]],64]);
 {n,width,pos}=If[First[codes]==63,With[{w=read[2,1]},{read[3,w],w,3+w}],{First[codes],1,2}];
 assert[n>0&&IntegerQ[n],"EmptyTriangulation"];
 (* each character packs three base-4 facet actions; actions past 4n faces are padding *)
 addAction[{acts_,u_},a_]:=If[u<4 n,assert[a<=2,"InvalidFacetAction"];{Append[acts,a],u+If[a==0,1,2]},
  assert[a==0,"InvalidPadding"];{acts,u}];
 {actions,used,pos}=NestWhile[Append[Fold[addAction,Most[#],Reverse[IntegerDigits[read[Last[#],1],4,3]]],Last[#]+1]&,
  {{},0,pos},#[[2]]<4 n&];
 assert[used==4 n,"FacetCountMismatch"];
 assert[FreeQ[actions,0],"BoundaryFacesUnsupported"];
 m=Count[actions,2];
 dests=read[pos+width (#-1),width]& /@ Range[m];perms=read[pos+width m+#-1,1]& /@ Range[m];
 assert[pos+(width+1) m==Length[codes]+1,"TrailingSignatureData"];
 assert[AllTrue[dests,0<=#<n&]&&AllTrue[perms,0<=#<24&],"InvalidGluingIndex"];
 perms=Sort[Permutations[Range[0,3]]][[perms+1]];
 (* state: {gluing table, next action, next new tetrahedron, next join} *)
 glue[{tab_,a_,nx_,jn_},{t_,f_}]:=If[tab[[t+1,f+1]]=!=Null,{tab,a,nx,jn},
  assert[a<=Length[actions],"MissingFacetAction"];
  With[{fresh=actions[[a]]==1},If[!fresh,assert[jn<=m,"MissingJoin"]];
  With[{j=If[fresh,nx,dests[[jn]]],p=If[fresh,Range[0,3],perms[[jn]]]},
  assert[0<=j<n,"InvalidDestination"];
  assert[tab[[j+1,p[[f+1]]+1]]===Null,"InvalidFacePair"];
  assert[!(j==t&&p[[f+1]]==f),"SelfPairedFace"];
  {ReplacePart[tab,{{t+1,f+1}->{j,p},{j+1,p[[f+1]]+1}->{t,Ordering[p]-1}}],a+1,nx+Boole[fresh],jn+Boole[!fresh]}]]];
 {table,ai,next,ji}=Fold[glue,{ConstantArray[Null,{n,4}],1,1,1},Tuples[{Range[0,n-1],Range[0,3]}]];
 assert[next==n&&ai==Length[actions]+1&&ji==m+1,"DisconnectedOrMalformed"];
 records=Flatten[Table[<|"tetrahedron"->t-1,"face"->f-1,"neighbor"->table[[t,f,1]],
  "vertex_permutation"->table[[t,f,2]]|>,{t,n},{f,4}],1];
 orient[o_,{j_,k_,p_,_}]:=If[o[[j+1]]==0,o,With[{sgn=-Signature[p] o[[j+1]]},
  assert[o[[k+1]]==0||o[[k+1]]==sgn,"NonOrientableTriangulation"];ReplacePart[o,k+1->sgn]]];
 <|"Signature"->s,"Tetrahedra"->n,"FacePairings"->records,
  "Orientations"->FixedPoint[Fold[orient,#,gluings[records]]&,UnitVector[n,1]],
  "PeripheralDecoration"->If[Length[parts]>1,parts[[2]],None]|>
];
ValidateIdealTriangulation[t_Association]:=Catch@Module[
 {n=t["Tetrahedra"],fp=t["FacePairings"],pairs,index,vid,eid,cusps,corners,sides,labels,cuspOf,perCusp,chi},
 pairs=Select[Tuples[Range[0,3],2],Unequal@@#&];index=First /@ PositionIndex[pairs];
 vid[j_,v_]:=4 j+v+1;
 eid[j_,e_]:=12 j+index[e];
 cusps=ConnectedComponents[gluingGraph[4 n,fp,vid,DeleteCases[Range[0,3],#]&]];
 corners=ConnectedComponents[gluingGraph[12 n,fp,eid,Select[pairs,FreeQ[#]]&]];
 sides=ConnectedComponents[gluingGraph[12 n,fp,eid,Function[f,{#,f}& /@ DeleteCases[Range[0,3],f]]]];
 labels=componentLabels[corners];
 assert[AllTrue[Tuples[{Range[0,n-1],pairs}],labels[eid@@#]!=labels[eid[#[[1]],Reverse[#[[2]]]]]&],"ReversedEdge"];
 (* number of corner (or side) classes per cusp, located by the ideal vertex of a representative *)
 cuspOf=componentLabels[cusps];
 perCusp[comps_]:=Lookup[Counts[cuspOf[vid[Quotient[First[#]-1,12],pairs[[Mod[First[#]-1,12]+1,1]]]]& /@ comps],
  Range[Length[cusps]],0];
 chi=perCusp[corners]-perCusp[sides]+Length /@ cusps;
 assert[AllTrue[chi,#==0&],"NonTorusVertexLinks",<|"EulerCharacteristics"->chi|>];
 <|"Cusps"->Length[cusps],"VertexLinkEulerCharacteristics"->chi,"ReversedEdges"->False|>
];
AngleSystem[t_Association]:=Module[{n=t["Tetrahedra"],edges,index,classes,typ={1,2,3,3,2,1},ae,a,b},
 edges=Subsets[Range[0,3],{2}];index=First /@ PositionIndex[edges];
 classes=ConnectedComponents[gluingGraph[6 n,t["FacePairings"],6 #1+index[Sort[#2]]&,
  Subsets[DeleteCases[Range[0,3],#],{2}]&]];
 ae=Normal[SparseArray[Normal[Counts[(3 Quotient[#-1,6]+typ[[Mod[#-1,6]+1]])& /@ #]],3 n]]& /@ classes;
 a=Join[KroneckerProduct[IdentityMatrix[n],{{1,1,1}}],ae];
 b=Join[ConstantArray[1,n],ConstantArray[2,Length[classes]]];
 <|"Matrix"->a,"RightHandSideInPiUnits"->b,"EdgeMatrix"->ae,
 "EdgeClasses"->classes,"NullSpace"->NullSpace[a]|>
];
lobVolume[v_]:=Total[Im[PolyLog[2,Exp[2 I #]]]/2& /@ v];
SolveCompleteStructure[t_Association,wp_Integer:120,goal_Integer:45]:=Catch@Module[
 {sys,n=t["Tetrahedra"],a,b,vars,h,lin,bn,gradient,residual,newtonStep,steps,theta,res,
 z,signed,logs,edgeResidual},
 assert[goal>0&&wp>=2 goal+20,"InsufficientWorkingPrecision"];
 With[{validation=ValidateIdealTriangulation[t]},If[FailureQ[validation],Throw[validation]]];
 sys=AngleSystem[t];a=sys["Matrix"];b=sys["RightHandSideInPiUnits"];
 vars=Array[Unique["angle"]&,3 n];h=Unique["margin"];
 lin=LinearOptimization[-h,Join[Thread[a.vars==b],Thread[vars>=h],{h>=0}],
 Append[vars,h],"PrimalMinimizer"];
 assert[VectorQ[lin,NumericQ]&&Last[lin]>0,"NoStrictAngleStructure"];
 bn=N[sys["NullSpace"],wp];
 gradient[th_]:=-bn.Log[2 Sin[th]];
 residual[th_]:=Max[Abs[gradient[th]]];
 (* one damped Newton step: {angles, _} -> {new angles, history record} *)
 newtonStep[{th_,_}]:=Module[{grad=gradient[th],old=lobVolume[th],step,delta,rate,new},
  step=-LinearSolve[-bn.DiagonalMatrix[Cot[th]].Transpose[bn],grad];delta=step.bn;
  rate=NestWhile[With[{r=#/2},assert[r>2^-100,"NewtonLineSearchFailed"];r]&,1,
   With[{trial=th+# delta},Min[trial]<=0||Max[trial]>=Pi||lobVolume[trial]<old+# grad.step/10000]&];
  new=SetPrecision[th+rate delta,wp];
  {new,<|"Volume"->lobVolume[new],"GradientResidualBeforeStep"->Max[Abs[grad]],"StepFraction"->rate|>}];
 steps=NestWhileList[newtonStep,{N[Pi Most[lin],wp],None},!TrueQ[residual[First[#]]<10^-goal]&,1,80];
 theta=steps[[-1,1]];res=residual[theta];
 assert[TrueQ[res<10^-goal],"NoInteriorCriticalPoint",<|"Residual"->res|>];
 z=Sin[#[[2]]]/Sin[#[[3]]] Exp[I #[[1]]]& /@ Partition[theta,3];
 signed=MapThread[If[#2==1,#1,Conjugate[#1]]&,{z,t["Orientations"]}];
 logs=Flatten[MapThread[#2 {Log[#1],Log[1/(1-#1)],Log[(#1-1)/#1]}&,
 {signed,t["Orientations"]}]];
 edgeResidual=Max[Abs[Exp[sys["EdgeMatrix"].logs]-1]];
 assert[edgeResidual<10^(-goal+5),"ComplexEdgeEquationsFailed"];
 <|"Angles"->theta,"UnsignedShapes"->z,"ShapesInOriginalLabels"->signed,
 "Volume"->lobVolume[theta],"BlochWignerVolume"->Total[Im[PolyLog[2,#]]+Arg[1-#] Log[Abs[#]]& /@ z],
 "QuadratureVolume"->Total[-NIntegrate[Log[2 Sin[u]],{u,0,#},WorkingPrecision->wp,
  AccuracyGoal->goal,PrecisionGoal->goal,Method->{"GlobalAdaptive","SymbolicProcessing"->0}]& /@ theta],
 "GradientResidual"->res,"AngleEquationResidual"->Max[Abs[a.theta-Pi b]],
 "ComplexEdgeResidual"->edgeResidual,"MinimumAngle"->Min[theta],
 "WorkingPrecision"->wp,"RequestedGoal"->goal,
 "History"->MapIndexed[Prepend[Last[#1],"Iteration"->First[#2]]&,Rest[steps]],"AngleSystem"->sys|>
];
tripleMap[src_,dst_]:=Module[{rows,h},
 rows=MapThread[Function[{u,v},{v[[2]] u[[1]],v[[2]] u[[2]],-v[[1]] u[[1]],-v[[1]] u[[2]]}],{src,dst}];
 h=Partition[First[NullSpace[rows]],2];h/Sqrt[Det[h]]];
BuildHolonomy[t_Association,s_Association]:=Module[
 {n=t["Tetrahedra"],glu=gluings[t["FacePairings"]],pts,trans,links,develop,dev,gen,c={{1,-(1/2+I/3)},{0,1}}},
 pts=({{1,0},{0,1},{1,1},{#,1}}& /@ s["ShapesInOriginalLabels"]);
 trans=Function[{j,k,p,f},With[{v=DeleteCases[Range[0,3],f]+1},
  tripleMap[pts[[k+1,p[[v]]+1]],pts[[j+1,v]]]]]@@@glu;
 (* {tetrahedron, neighbor, transition}, 1-based *)
 links=MapThread[Append,{glu[[All,{1,2}]]+1,trans}];
 develop[d_,{j_,k_,m_}]:=If[MatrixQ[d[[j]]]&&!MatrixQ[d[[k]]],ReplacePart[d,k->d[[j]].m],d];
 dev=FixedPoint[Fold[develop,#,links]&,ReplacePart[ConstantArray[0,n],1->IdentityMatrix[2]]];
 gen=c.#.Inverse[c]& /@ ((dev[[#1]].#3.Inverse[dev[[#2]]]&)@@@links);
 gen=DeleteDuplicates[Select[gen,nontrivialQ[#,10^-20]&],Min[Norm[#1-#2],Norm[#1+#2]]<10^-20&];
 <|"Generators"->gen,"DevelopingMaps"->dev,"FaceTransitions"->trans,
 "BasepointUpperHalfSpace"->{1/2,1/3,1}|>
];
orbit[g_]:=Module[{m=g.ConjugateTranspose[g]},
 Re[{Tr[m]/2,m[[1,2]],-I m[[1,2]],(m[[1,1]]-m[[2,2]])/2}]];
bisectorNormal[g_]:=With[{o=orbit[g]},Rest[o]/(First[o]-1)];
kleinAction[g_,v_]:=Module[{m=g.{{1+v[[3]],v[[1]]+I v[[2]]},
 {v[[1]]-I v[[2]],1-v[[3]]}}.ConjugateTranspose[g]},
 Re[{2 m[[1,2]],-2 I m[[1,2]],m[[1,1]]-m[[2,2]]}/Tr[m]]];
(* One refinement round: keep the generators whose bisectors bound the domain, find the domain
   vertices from the polar hull, and collect the products that still cut the domain. *)
refineDomain[gens_]:=Module[{all=bisectorNormal /@ gens,hull,near,keep,pool,normals,dual,vertices},
 hull=ConvexHullMesh[all];near=Nearest[all->"Index"];
 keep=First[near[#]]& /@ MeshCoordinates[hull][[DeleteDuplicates[Flatten[MeshCells[hull,2][[All,1]]]]]];
 pool=gens[[keep]];normals=bisectorNormal /@ pool;dual=ConvexHullMesh[normals];
 vertices=DeleteDuplicates[Quiet[LinearSolve[MeshCoordinates[dual][[Take[First[#],3]]],{1.,1.,1.}]]& /@
  MeshCells[dual,2],Norm[#1-#2]<10^-7&];
 assert[MatrixQ[vertices,NumericQ],"DegeneratePolarHull"];
 <|"Pool"->pool,"Normals"->normals,"Vertices"->vertices,"Candidates"->
  Select[DeleteDuplicatesBy[Select[Join[pool,Catenate[Outer[Dot,pool,pool,1]]],nontrivialQ[#,10^-7]&],
   Round[bisectorNormal[#],10^-7]&],Max[vertices.bisectorNormal[#]]>1+10^-8&]|>];
BuildDirichletDomain[h_Association,maxIterations_Integer:12]:=Catch@Module[
 {steps,pool,normals,vertices,faceCycle,faces,edges,edgeIndex,near,invNormals,facePairs,
 pairing,pairings,pairResidual,edgeClasses,dihedral,angles,residual},
 assert[maxIterations>0,"DomainDidNotStabilize"];
 steps=NestWhileList[refineDomain[Join[#Pool,#Candidates]]&,refineDomain[N[h["Generators"]]],
  #Candidates=!={}&,1,maxIterations-1];
 assert[Last[steps]["Candidates"]==={},"DomainDidNotStabilize"];
 {pool,normals,vertices}=Lookup[Last[steps],{"Pool","Normals","Vertices"}];
 assert[Max[Norm /@ vertices]<1+10^-7,"DomainExtendsOutsideBall"];
 assert[Max[Flatten[vertices.Transpose[normals]]]<1+10^-7,"HalfSpaceViolation"];
 (* vertices on the bisector plane q.x==1, in angular order around their centroid *)
 faceCycle[q_]:=Module[{ids=Flatten[Position[Abs[vertices.q-1],x_/;x<10^-7]],pts,ctr,u,v},
  assert[Length[ids]>=3,"DegenerateFace"];pts=vertices[[ids]];ctr=Mean[pts];
  u=Normalize[First[pts]-ctr];v=Normalize[Cross[q,u]];
  ids[[Ordering[ArcTan[(#-ctr).u,(#-ctr).v]& /@ pts]]]];
 faces=faceCycle /@ normals;
 edges=DeleteDuplicates[Sort /@ Catenate[cyclicPairs /@ faces]];edgeIndex=First /@ PositionIndex[edges];
 assert[Length[vertices]-Length[edges]+Length[faces]==2,"PolyhedronEulerCheckFailed"];
 near=Nearest[vertices->"Index"];
 invNormals=bisectorNormal /@ (Inverse /@ pool);
 facePairs=(First[Nearest[normals->"Index",#]]& /@ invNormals);
 assert[Max[Norm /@ (invNormals-normals[[facePairs]])]<10^-7,"MissingInverseFace"];
 (* face i -> {vertex residual of its pairing, links from its edges to their images} *)
 pairing[i_]:=Module[{g=Inverse[pool[[i]]],mapped,ids},
  mapped=kleinAction[g,#]& /@ vertices[[faces[[i]]]];ids=First[near[#]]& /@ mapped;
  assert[Sort[ids]==Sort[faces[[facePairs[[i]]]]],"FacePairingMismatch"];
  {Max[Norm /@ (mapped-vertices[[ids]])],
   Function[e,UndirectedEdge[edgeIndex[Sort[e]],edgeIndex[Sort[First[near[kleinAction[g,#]]]& /@ vertices[[e]]]]]] /@
    cyclicPairs[faces[[i]]]}];
 pairings=pairing /@ Range[Length[faces]];
 pairResidual=Max[0.,pairings[[All,1]]];
 assert[pairResidual<10^-7,"PairingVertexResidualTooLarge"];
 edgeClasses=ConnectedComponents[Graph[Range[Length[edges]],Catenate[pairings[[All,2]]]]];
 dihedral[e_]:=With[{ff=Select[Range[Length[faces]],SubsetQ[faces[[#]],e]&]},
  assert[Length[ff]==2,"InvalidPolyhedronEdge"];
  With[{n1=normals[[ff[[1]]]],n2=normals[[ff[[2]]]]},ArcCos[Clip[(1-n1.n2)/Sqrt[(n1.n1-1)(n2.n2-1)],{-1,1}]]]];
 angles=dihedral /@ edges;
 residual=Max[Abs[(Total[angles[[#]]]& /@ edgeClasses)-2 Pi]];
 assert[residual<10^-7,"EdgeCycleAngleCheckFailed"];
 <|"Vertices"->vertices,"Normals"->normals,"Faces"->faces,"Edges"->edges,
 "Generators"->pool,"FacePairs"->facePairs,"EdgeClasses"->edgeClasses,
 "PairingVertexResidual"->pairResidual,"EdgeCycleAngleResidual"->residual,
 "IdealVertices"->Flatten[Position[Norm /@ vertices,x_/;Abs[x-1]<10^-7]],
 "History"->MapIndexed[<|"Iteration"->First[#2],"Faces"->Length[#1["Pool"]],
  "Vertices"->Length[#1["Vertices"]],"NewCuts"->Length[#1["Candidates"]]|>&,steps],
 "Status"->"Numerically checked candidate; not certified"|>
];
(* fan triangulation {centroid, v_i, v_(i+1)} of a polygonal face *)
fanTriangles[verts_,f_]:=With[{p=verts[[f]]},Prepend[#,Mean[p]]& /@ cyclicPairs[p]];
fluxIntegral[t_,goal_]:=Module[{a,b,c,jac,fun},
 {a,b,c}=SetPrecision[t,30];
 {b,c}=If[Abs[#.#-1]<10^-7,Normalize[#],#]& /@ {b,c};
 jac=Abs[Det[{a,b-a,c-a}]];
 fun[u_?NumericQ,w_?NumericQ]:=Module[{r=Norm[a+u (b-a)+(1-u) w (c-a)]},
 jac (1-u) (r/(1-r^2)-ArcTanh[r])/(2 r^3)];
 NIntegrate[fun[u,w],{u,0,1},{w,0,1},WorkingPrecision->30,
 AccuracyGoal->goal,PrecisionGoal->goal,MaxRecursion->20,
 Method->{"GlobalAdaptive","SymbolicProcessing"->0}]];
IntegrateDomainVolume[d_Association,goal_Integer:8]:=Module[
 {tri=Catenate[fanTriangles[d["Vertices"],#]& /@ d["Faces"]],values},
 values=fluxIntegral[#,goal]& /@ tri;
 <|"Volume"->Total[values],"Triangles"->Length[tri],"PerTriangleGoal"->goal,
 "GeometryPrecision"->"Machine precision","TriangleIntegrals"->values|>
];
toPoincare[k_]:=k/(1+Sqrt[Max[0,1-k.k]]);
splitTriangle[{a_,b_,c_}]:={{a,(a+b)/2,(a+c)/2},{b,(b+c)/2,(a+b)/2},
 {c,(a+c)/2,(b+c)/2},{(a+b)/2,(b+c)/2,(a+c)/2}};
DomainGraphics[d_Association,model_String:"Poincare"]:=Module[
 {verts=d["Vertices"],map=If[model=="Klein",Identity,toPoincare],polys,curves},
 polys=Nest[Catenate[splitTriangle /@ #]&,Catenate[fanTriangles[verts,#]& /@ d["Faces"]],2];
 curves=Table[Line[map /@ Table[(1-u) verts[[e[[1]]]]+u verts[[e[[2]]]],{u,0,1,1/24}]],{e,d["Edges"]}];
 Graphics3D[{{Opacity[.32],RGBColor[.15,.55,.82],EdgeForm[None],Polygon[map /@ #]& /@ polys},
 {RGBColor[.12,.25,.4],AbsoluteThickness[1],curves},
 {RGBColor[.95,.4,.15],PointSize[.02],Point[map /@ verts[[d["IdealVertices"]]]]},
 {Gray,PointSize[.012],Point[{0,0,0}]}},Boxed->False,Lighting->"Neutral",
 PlotRange->{{-1,1},{-1,1},{-1,1}},ImageSize->600,SphericalRegion->True,
 PlotLabel->Row[{"Dirichlet domain — ",model," model"}]]
];
End[];
EndPackage[];
