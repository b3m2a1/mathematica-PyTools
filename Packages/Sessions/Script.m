(* ::Package:: *)



$PyMLibDirectory::usage="The default dir for finding python scripts";
$PyRunHeader::usage="The header to insert before PyRun calls";
PyMScript::usage="Represents a mathematica_script inside a python run";
PyMExport::usage="Represents a mathematica_export inside a python run";
PyMExportParse::usage="Parses the JSON returned by a script"


PackageScopeBlock[$PyExportKey]


Begin["`Private`"];


ToPython (* Load all of the symbolic parameters *)


$PyMLibDirectory=
	PackageFilePath["Resources"(*, "MScript"*)];


If[!ValueQ[$PyExportKey],
	$PyExportKey=CreateUUID["python-export-"]
	];


$PyRunHeader:=
	PyColumn[{
		PyIf[PyNot@PyMemberQ[$PySysPath,PyString@$PyMLibDirectory]][
			PySysPathInsert[PyString@$PyMLibDirectory],
			PyImport["MLib"],
			PyAssign[
				PyIndex[
					PyDot["MLib","mathematica_export_parameters"],
					PyString@"Delimiter"
					],
				PyString@$PyExportKey
				]
			]
		}]


PyMJSONImport[base_]:=
	With[{
		strQ=MatchQ[Lookup[base, "ReturnType"], Except["File"|"TemporaryFile"]],
		coreFMT=
			Replace["JSON"->"RawJSON"]@
			Lookup[base, 
				"ReturnFormat", 
				Switch[Lookup[base, "ReturnType"],
					"Bytes",
						"String",
					"File"|"TemporaryFile", 
						If[FileExtension[Lookup[base,"ReturnValue"]]==="",
							"RawJSON",
							None
							],
					_,
						"RawJSON"
					]
				],
		coreData=
			Switch[Lookup[base, "ReturnType", "String"],
				"Bytes",
					Developer`DecodeBase64[
						StringTrim[Lookup[base, "ReturnValue"],"b'"|"'"]
						]
					(*If[$VersionNumber\[GreaterEqual]11.2,
						ByteArrayToString@
							ByteArray@Lookup[base, "ReturnValue"],
						With[{tmp = CreateFile[]},
							BinaryWrite[tmp, Lookup[base, "ReturnValue"]];
							Function[DeleteFile[tmp];#]@Import[tmp, "String"]
							]
						]*),
				_,
					Lookup[base, "ReturnValue"]
				]
		},
	If[coreFMT==="RawJSON",
		Quiet[
			Check[
				If[strQ,ImportString,Import][coreData,coreFMT],
				If[strQ,ImportString,Import][coreData,"JSON"],
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
		If[strQ,ImportString,Import][
			Global`a = coreData,
			If[coreFMT===None, Sequence@@{}, coreFMT]
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
						"String"|"Bytes":>
							Quiet[
								Check[
									PyMJSONImport[base],
									Lookup[base, "ReturnValue"],
									Import::fmterr
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



