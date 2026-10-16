BeginPackage["DTCrossingTable`"];
DTCrossingTable::usage="DTCrossingTable[code] decodes a one-component Dowker-Thistlethwaite code (list of signed even integers) into its crossings; a negative entry means the even-labelled visit is the over strand.";
Begin["`Private`"];
assert[c_,tag_,details_:<||>]:=If[!TrueQ[c],Throw[Failure[tag,details]]];
DTCrossingTable[code_List]:=Catch@Module[{n=Length[code],odd,even,crossings},
 assert[n>0&&VectorQ[code,IntegerQ],"InvalidDTCode"];
 assert[And@@(EvenQ /@ code)&&Sort[Abs[code]]==2 Range[n],"InvalidDTCode",<|"Code"->code|>];
 odd=2 Range[n]-1;even=Abs[code];
 crossings=MapThread[<|"OddVisit"->#1,"EvenVisit"->#2,"Over"->If[#3<0,"Even","Odd"]|>&,{odd,even,code}];
 <|"Crossings"->n,"Table"->crossings|>
];
End[];
EndPackage[];
