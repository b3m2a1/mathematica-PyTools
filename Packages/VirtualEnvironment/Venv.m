(* ::Package:: *)



$VenvRoot::usage="The base location to look for venvs";
VenvNew::usage="Makes a new virtual environment";
VenvDir::usage="Provides the virtual environment directory";


Begin["`Private`"];


$VenvRoot=
	If[$OperatingSystem=!="Windows"&&DirectoryQ@"~/Documents/Python/config",
		ExpandFileName@"~/Documents/Python/config",
		FileNameJoin@{$HomeDirectory,"virtualenvs"}
		];


Options[VenvNew]=
	{
		"Version"->None
		};
VenvNew[
	name_String?(StringLength[DirectoryName@#]>0&&DirectoryQ@DirectoryName[#]&),
	ops:OptionsPattern[]
	]:=
	(
		Quiet[CreateDirectory[name]];
		SetDirectory[name];
		(ResetDirectory[];#)&@
			RunProcess[{
				"virtualenv",
				FileBaseName@name
				},
				ProcessEnvironment->
					<|
						"PATH"->
							"/usr/local/bin:"<>Environment["PATH"]
						|>]
		);
VenvNew[name_String?(StringMatchQ[Except[$PathnameSeparator]..])]:=
	(
		If[!DirectoryQ[$VenvRoot],
			CreateDirectory[$VenvRoot]
			];
		VenvNew[FileNameJoin@{$VenvRoot,name}]
		)


VenvDir[dir_String?VenvDirQ]:=
 dir;
VenvDir[name_String?(Not@*VenvDirQ)]:=
 (
	If[!DirectoryQ[$VenvRoot],
		CreateDirectory[$VenvRoot]
		];
	If[DirectoryQ@FileNameJoin@{$VenvRoot,name},
	  FileNameJoin@{$VenvRoot,name},
	  $Failed
	 ]
	)
VenvDirQ[_]:=$Failed


VenvDirQ[dir_String?DirectoryQ]:=
	FileExistsQ[FileNameJoin@{dir,"bin","activate"}];
VenvDirQ[_]:=False;


End[];



