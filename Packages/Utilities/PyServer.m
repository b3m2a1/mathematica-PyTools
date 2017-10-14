(* ::Package:: *)

(************************************************************************)
(* This file was generated automatically by the Mathematica front end.  *)
(* It contains Initialization cells from a Notebook file, which         *)
(* typically will have the same name as this file except ending in      *)
(* ".nb" instead of ".m".                                               *)
(*                                                                      *)
(* This file is intended to be loaded into the Mathematica kernel using *)
(* the package loading commands Get or Needs.  Doing so is equivalent   *)
(* to using the Evaluate Initialization Cells menu command in the front *)
(* end.                                                                 *)
(*                                                                      *)
(* DO NOT EDIT THIS FILE.  This entire file is regenerated              *)
(* automatically each time the parent Notebook file is saved in the     *)
(* Mathematica front end.  Any changes you make to this file will be    *)
(* overwritten.                                                         *)
(************************************************************************)



$PyServer::usage=
	"The current server instance";
PyServerStart::usage=
	"Starts a server instance";
PyServerOpen::usage=
	"Opens a file using a SimpleHTTPServer or opens the server itself";


Begin["`Private`"];


$PyServer::unsupported=
	"$OperatingSystem isn't supported by SimpleHTTPServer";


$PyServerName="_SERVER";


$PyServer:=
	If[PySessionActive[$PyServerName],PySession[$PyServerName],None];


Options[PyServerStart]=
	{
		"Port"->Automatic,
		"Path"->None
		};
PyServerStart[
	root:(_String|_File)?DirectoryQ|Automatic:Automatic,
	ops:OptionsPattern[]
	]:=
	With[{
		port=
			Replace[OptionValue["Port"],{
				Automatic->"7001",
				e_:>ToString[e]
				}],
		path=
			Replace[OptionValue["Path"],{
				Automatic->{},
				s_String?FileExistsQ:>
					FileNameSplit[s],
				p_String:>
					URLParse[p,"Path"]
				}],
		dir=Replace[root,Automatic:>Directory[]]
		},
		If[$OperatingSystem=!="Windows",
			PySessionKill[$PyServerName];
			PySessionStart[$PyServerName,
				"PythonConfig"->
					{"-m","SimpleHTTPServer",port},
				"Version"->"2.7",
				"MetaInfo"->
					<|
						"Root"->dir,
						"Port"->port
						|>
				];
			If[path=!=None,
				SystemOpen@
					URLBuild@<|
						"Scheme"->"http",
						"Domain"->"localhost",
						"Port"->port,
						"Path"->path
						|>
				];,
			Message[PySimpleServer::unsupported];
			$Failed
			]
	];


Options[PyServerOpen]=
	Options[PyServerStart];
PyServerOpen[
	path:_String?FileExistsQ|Automatic:Automatic,
	ops:OptionsPattern[]
	]:=
	With[{
		p=
			Replace[path,
				Automatic:>
					If[PySessionActive[$PyServerName],
						PySessionMeta[$PyServerName]["Root"],
						Directory[]
						]
				]
		},
		If[PySessionActive[$PyServerName]&&
			StringStartsQ[
				ExpandFileName[p],
				ExpandFileName@
					PySessionMeta[$PyServerName]["Root"]
				],
			SystemOpen@
				URLBuild@
					<|
						"Scheme"->"http",
						"Domain"->"localhost",
						"Port"->PySessionMeta[$PyServerName]["Port"],
						"Path"->
							FileNameSplit@
								FileNameDrop[
									ExpandFileName[p],
									FileNameDepth@
										ExpandFileName[PySessionMeta[$PyServerName]["Root"]]
									]
						|>,
			PyServerStart[
				If[DirectoryQ@p,p,DirectoryName[p]],
				"Path"->
					If[DirectoryQ@p,Automatic,FileNameTake@p],
				ops
				]
			]
		]


End[];


