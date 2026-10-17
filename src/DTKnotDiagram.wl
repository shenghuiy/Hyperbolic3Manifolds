(* Planar knot diagrams from Dowker-Thistlethwaite codes. Follows the vertex model of
   spherogram's codecs/DT.py (first visit enters South and leaves North, second visit enters
   East and leaves West, a flip swaps the North and South edges) so that flips, PD codes and
   crossing signs agree with SnapPy. The flips of a bare code are found by a pruned search
   instead of SnapPy's bridge procedure. *)
Get[FileNameJoin[{DirectoryName[$InputFileName],"DTCrossingTable.wl"}]];
BeginPackage["DTKnotDiagram`",{"DTCrossingTable`"}];
DTPlanarData::usage="DTPlanarData[code] or DTPlanarData[code,flips] embeds a one-component DT code (list of signed even integers, or a SnapPy letter string such as \"nanbeIKaMNLCGDHJF.00001110101100\" whose suffix gives the flips) in the sphere. Returns the flips, the PD code (arc labels 1..2n, as DTcodec.PD_code), the cyclic dart order at every crossing and the faces, or a Failure.";
DTDiagramLayout::usage="DTDiagramLayout[data] places the crossings of a DTPlanarData result in the plane by a Tutte embedding with face-centre vertices and returns positions, edge curves and under-strand ends.";
DTKnotDiagram::usage="DTKnotDiagram[code] draws the knot diagram of a DT code, with a gap in every under-strand.";
Begin["`Private`"];
assert[c_,tag_,details_:<||>]:=If[!TrueQ[c],Throw[Failure[tag,details]]];
letterValue[ch_String]:=With[{k=First[ToCharacterCode[ch]]},
 Which[96<k<123,k-96,64<k<91,64-k,True,Throw[Failure["InvalidDTLetter",<|"Character"->ch|>]]]];
parseDTString[s_String]:=Module[{parts=StringSplit[s,"."],ints,n,flips=Automatic},
 assert[Length[parts]>=1&&StringLength[First[parts]]>3,"InvalidDTString"];
 ints=letterValue /@ Characters[First[parts]];
 n=First[ints];
 assert[ints[[2]]==1,"MultiComponentUnsupported"];
 assert[Length[ints]==n+3&&ints[[3]]==n,"InvalidDTString"];
 If[Length[parts]>1,
  assert[StringLength[parts[[2]]]==n&&StringMatchQ[parts[[2]],RegularExpression["[01]+"]],"InvalidDTFlips"];
  flips=ToExpression /@ Characters[parts[[2]]]];
 {2 ints[[4;;]],flips}];
DTPlanarData[s_String]:=Catch@Apply[DTPlanarData,parseDTString[s]];
DTPlanarData[s_String,flips_List]:=Catch@Module[{p=parseDTString[s]},DTPlanarData[First[p],flips]];
DTPlanarData[code_List]:=DTPlanarData[code,Automatic];
DTPlanarData[code_List,flipsIn_]:=Catch@Module[
 {n=Length[code],n2,t,lo,hi,eo,crossOf,enterD,exitD,rot,arcs,dartVertex,opp,order,planarQ,
  search,flips,assoc,sigma,phi,orbits,seen,start,orbit,d,rots,pd,faces},
 t=DTCrossingTable[code];assert[!FailureQ[t],"InvalidDTCode",<|"Code"->code|>];
 n2=2 n;
 lo=Table[Min[2 c-1,Abs[code[[c]]]],{c,n}];hi=Table[Max[2 c-1,Abs[code[[c]]]],{c,n}];
 eo=Table[code[[c]]<0,{c,n}];
 crossOf=Association@Flatten[Table[{(2 c-1)->c,Abs[code[[c]]]->c},{c,n}]];
 enterD[v_]:={If[v==1,n2,v-1],1};exitD[v_]:={v,0};
 rot[c_,f_]:=If[f==0,{enterD[lo[[c]]],enterD[hi[[c]]],exitD[lo[[c]]],exitD[hi[[c]]]},
  {exitD[lo[[c]]],enterD[hi[[c]]],enterD[lo[[c]]],exitD[hi[[c]]]}];
 arcs=Association@Table[k->{crossOf[k],crossOf[If[k==n2,1,k+1]]},{k,n2}];
 dartVertex[{k,e_}]:=arcs[k][[e+1]];
 opp[{k_,e_}]:={k,1-e};
 (* a partial assignment is admissible when the ribbon graph it induces is planar *)
 planarQ[fl_Association]:=Module[{A=Keys[fl],inc,r,sg=<||>,ph,orb=0,sen=<||>,cur,fcount,v},
  inc=Select[Range[n2],KeyExistsQ[fl,arcs[#][[1]]]&&KeyExistsQ[fl,arcs[#][[2]]]&];
  fcount=0;
  Do[r=Select[rot[c,fl[c]],MemberQ[inc,First[#]]&];
   If[r==={},fcount++,Do[sg[r[[i]]]=r[[Mod[i,Length[r]]+1]],{i,Length[r]}]],{c,A}];
  Do[If[!KeyExistsQ[sen,d0],cur=d0;
   While[!KeyExistsQ[sen,cur],sen[cur]=True;cur=sg[opp[cur]]];fcount++],
   {d0,Keys[sg]}];
  Length[A]-Length[inc]+fcount==2];
 order=DeleteDuplicates[crossOf /@ Range[n2]];
 search[i_,fl_]:=If[i>n,Throw[fl,"found"],
  Do[With[{nf=Append[fl,order[[i]]->f]},If[planarQ[nf],search[i+1,nf]]],{f,If[i==1,{0},{0,1}]}]];
 If[flipsIn===Automatic,
  flips=Catch[search[1,<||>];None,"found"];
  assert[AssociationQ[flips],"NotPlanar",<|"Code"->code|>];
  If[flips[1]!=Boole[eo[[1]]],flips=Association[#->1-flips[#]& /@ Keys[flips]]];
  flips=Table[flips[c],{c,n}],
  assert[VectorQ[flipsIn,MemberQ[{0,1,True,False},#]&]&&Length[flipsIn]==n,"InvalidFlips"];
  flips=flipsIn /. {True->1,False->0};
  assert[planarQ[AssociationThread[Range[n],flips]],"NotPlanar",<|"Code"->code|>]];
 rots=Association@Table[c->rot[c,flips[[c]]],{c,n}];
 pd=Table[With[{u=If[eo[[c]],2 c-1,Abs[code[[c]]]]},
  First /@ RotateLeft[rots[c],First[First[Position[rots[c],enterD[u]]]]-1]],{c,n}];
 sigma=Association@Flatten[Table[Table[rots[c][[i]]->rots[c][[Mod[i,4]+1]],{i,4}],{c,n}],1];
 phi[d_]:=sigma[opp[d]];
 seen=<||>;faces={};
 Do[If[!KeyExistsQ[seen,d0],orbit={};d=d0;
  While[!KeyExistsQ[seen,d],seen[d]=True;AppendTo[orbit,d];d=phi[d]];AppendTo[faces,orbit]],
  {d0,Keys[sigma]}];
 assert[Length[faces]==n+2,"NotPlanar",<|"Code"->code|>];
 <|"Code"->code,"Flips"->flips,"PD"->pd,"Rotation"->rots,"Arcs"->arcs,"Faces"->faces,
  "UnderVisit"->Table[If[eo[[c]],2 c-1,Abs[code[[c]]]],{c,n}],"Crossings"->n|>
];
DTDiagramLayout[d_Association]:=Catch@Module[
 {faces=d["Faces"],arcs=d["Arcs"],n=d["Crossings"],n2,fv,fk,faceOf,cand,outer,m,inner,
  fixed=<||>,nodes,idx,edges,free,L,rhs,pos,sol,P,E,curves,under,len,gap,cyc,node},
 n2=2 n;
 fv=Table[arcs[First[#]][[Last[#]+1]]& /@ f,{f,faces}];
 fk=Table[First /@ f,{f,faces}];
 faceOf=Association@Flatten[Table[#->i& /@ faces[[i]],{i,Length[faces]}]];
 assert[And@@(#[[1]]=!=#[[2]]& /@ Values[arcs]),"UnsupportedDiagram",<|"Reason"->"loop (kink) in the diagram"|>];
 cand=Select[Reverse@SortBy[Range[Length[faces]],Length[fv[[#]]]&],DuplicateFreeQ[fv[[#]]]&];
 assert[cand=!={},"UnsupportedDiagram",<|"Reason"->"no face with a simple boundary"|>];
 outer=First[cand];inner=Select[Range[Length[faces]],#=!=outer&];
 (* node names: crossing c, arc-midpoint {"e",k}, inner face centre {"f",f} *)
 cyc=Flatten[Transpose[{fv[[outer]],{"e",#}& /@ fk[[outer]]}],1];
 m=Length[cyc];
 Do[fixed[cyc[[i]]]=N@{Cos[2 Pi (i-1)/m],Sin[2 Pi (i-1)/m]},{i,m}];
 nodes=Join[Range[n],{"e",#}& /@ Range[n2],{"f",#}& /@ inner];
 idx=AssociationThread[nodes,Range[Length[nodes]]];
 edges=DeleteDuplicates[Join[
  Flatten[Table[{{arcs[k][[1]],{"e",k}},{arcs[k][[2]],{"e",k}}},{k,n2}],1],
  Flatten[Table[{{"e",k},{"f",faceOf[{k,e}]}},{k,n2},{e,0,1}],1]/.{{"e",_},{"f",outer}}:>Nothing,
  Flatten[Table[{v,{"f",f}},{f,inner},{v,fv[[f]]}],1]]];
 free=Select[nodes,!KeyExistsQ[fixed,#]&];
 L=ConstantArray[0.,{Length[nodes],Length[nodes]}];
 Do[With[{i=idx[e[[1]]],j=idx[e[[2]]]},L[[i,i]]+=1.;L[[j,j]]+=1.;L[[i,j]]-=1.;L[[j,i]]-=1.],{e,edges}];
 pos=AssociationThread[nodes,ConstantArray[{0.,0.},Length[nodes]]];
 Do[pos[k]=fixed[k],{k,Keys[fixed]}];
 If[free=!={},
  rhs=Table[-Sum[L[[idx[i],idx[k]]] pos[k],{k,Keys[fixed]}],{i,free}];
  sol=LinearSolve[L[[idx/@free,idx/@free]],rhs];
  Do[pos[free[[i]]]=sol[[i]],{i,Length[free]}]];
 P=Association@Table[c->pos[c],{c,n}];
 E=Association@Table[k->pos[{"e",k}],{k,n2}];
 len=Median@Flatten[Table[{Norm[P[arcs[k][[1]]]-E[k]],Norm[P[arcs[k][[2]]]-E[k]]},{k,n2}]];
 gap=0.18 len;
 curves=Association@Table[k->{P[arcs[k][[1]]],E[k],P[arcs[k][[2]]]},{k,n2}];
 under=d["UnderVisit"];
 <|"Positions"->P,"EdgePoints"->E,"Curves"->curves,"Gap"->gap,"Outer"->outer,
  "UnderStart"->Association@Table[k->(k==under[[arcs[k][[1]]]]),{k,n2}],
  "UnderEnd"->Association@Table[k->(If[k==n2,1,k+1]==under[[arcs[k][[2]]]]),{k,n2}]|>
];
DTKnotDiagram[x_]:=Catch@Module[{d=DTPlanarData[x],lay,strands,smooth},
 assert[!FailureQ[d],"DTPlanarDataFailed"];
 lay=DTDiagramLayout[d];assert[!FailureQ[lay],"LayoutFailed"];
 smooth[{u_,e_,w_}]:=Table[(1-s)^2 u+2 s (1-s) e+s^2 w,{s,Subdivide[0,1,24]}];
 strands=Table[Module[{pts=smooth[lay["Curves"][k]],g=lay["Gap"]},
  If[lay["UnderStart"][k],pts=Drop[pts,LengthWhile[pts,Norm[#-First[pts]]<g&]]];
  If[lay["UnderEnd"][k],pts=Drop[pts,-LengthWhile[Reverse[pts],Norm[#-Last[pts]]<g&]]];
  If[Length[pts]>1,Line[pts],Nothing]],{k,2 d["Crossings"]}];
 Graphics[{AbsoluteThickness[2.5],CapForm["Round"],strands},ImageSize->500,PlotRangePadding->Scaled[.05]]
];
End[];
EndPackage[];
