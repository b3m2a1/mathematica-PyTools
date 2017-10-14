(* ::Package:: *)



$PyMLibDirectory::usage="The default dir for finding python scripts";
$PyRunHeader::usage="The header to insert before PyRun calls";
PyMScript::usage="Represents a mathematica_script inside a python run";
PyMExport::usage="Represents a mathematica_export inside a python run";
PyMExportParse::usage="Parses the JSON returned by a script"


Begin["`Private`"];


ToPython (* Load all of the symbolic parameters *)


$PyMLibDirectory=
	PackageFilePath["Resources"(*, "MScript"*)];


If[!ValueQ[$PyExportKey],
	$PyExportKey=CreateUUID["python-export-"]
	];


$PyRunHeader:=
	PyColumn[{
		PyIf[PyNot@PyMemberQ[$PySysPath,$PyMLibDirectory]][
			PySysPathInsert[$PyMLibDirectory],
			PyImport["MLib"],
			PyAssign[
				PyIndex[
					PyDot["MLib","mathematica_export_parameters"],
					PyString@"Delimiter"
					],
				$PyExportKey
				]
			]
		}]


PyMJSONImport[base_]:=
	With[{string=
		Lookup[base, "ReturnType", "String"]==="String"
		},
		With[{coreFMT=
			Replace["JSON"->"RawJSON"]@
			Lookup[base, "ReturnFormat", 
				If[string, 
					"RawJSON",
					If[FileExtension[Lookup[base,"ReturnValue"]]==="",
						"RawJSON",
						Sequence@@{}
						]
					]
				]
			},
		If[coreFMT==="RawJSON",
			Quiet[
				Check[
					If[string,ImportString,Import][Lookup[base, "ReturnValue"],coreFMT],
					If[string,ImportString,Import][Lookup[base, "ReturnValue"],"JSON"],
					{
						Import::jsonhintposition,
						Import::jsonhintposandchar,
						Import::jsonnullinput,
						Import::jsonkvsep,
						Import::jsonexpendofinput,
						Import::jsontokenmismatch,
						ImportString::string,
						ImportString::bkslsh,
						Import::jsoninvalidtoken
						}
					],
				{
					Import::jsonhintposition,
					Import::jsonhintposandchar,
					Import::jsonnullinput,
					Import::jsonkvsep,
					Import::jsonexpendofinput,
					Import::jsontokenmismatch,
					ImportString::string,
					ImportString::bkslsh,
					Import::jsoninvalidtoken
					}
				],
			If[string,ImportString,Import][base,coreFMT]
			]
		]
	]


PyMExportParse::wutret="Unsure how to parse \"ReturnType\" ``";
PyMExportParse[s_String]:=
	Replace[{a_}:>a]@
	StringCases[s,
		Shortest[$PyExportKey~~"\n"~~e__~~"\n"~~$PyExportKey]:>
			Replace[ImportString[e, "RawJSON"],{
				base_?OptionQ:>
					Replace[Lookup[base, "ReturnType", "String"],{
						"String":>
							Quiet[
								Check[
									PyMJSONImport[base],
									Lookup[base, "ReturnValue"]
									],
								Import::fmterr
								],
						"TemporaryFile":>
							With[{r=PyMJSONImport[base]},
								DeleteFile[Lookup[base,"ReturnValue"]];
								r
								],
						"File":>
							PyMJSONImport[base],
						else_:>
							Message[PyExportParse::wutret, else]
						}]
				}](*,
		1*)
		]


End[];



