(* ::Package:: *)



PySessions::usage="The current python sessions";
PySession::usage="A python session";
PySessionProcess::usage="The ProcessObject underlying a PySession";
PySessionType::usage="The Type underlying a PySession";
PySessionMeta::usage="The MetaInfo underlying a PySession";
PySessionWrite::usage="Writes to the PySession";
PySessionRead::usage="Reads from a PySession";
PySessionStart::usage="Starts a PySession";
PySessionKill::usage="Kills a PySession";
PySessionRemove::usage="Removes a PySession";
PySessionActive::usage="Tests whether a PySession is active or not";
PySessionRun::usage="Writes and reads from a PySession";


Begin["`Private`"];


If[!AssociationQ@$PySessions, $PySessions=<||>];


PySessions[False]:=
	$PySessions;
PySessions[Optional[True, True]]:=
	$PySessions//Dataset


Options[PySessionStart]=
 Join[
 	{
	  "SystemShell"->False,
	  "VirtualEnvironment"->None,
	  "Version"->Automatic,
		"PythonConfig"->{"-i"},
		"ShellConfig"->{},
		"MetaInfo"->{}
	  },
	 Options[StartProcess]
	 ];
PySessionStart[name:Except[_?OptionQ],
 ops:OptionsPattern[]
 ]:=
 Replace[
  pySessionCreateProcessObject[
  	OptionValue[{"SystemShell","VirtualEnvironment","Version"}],
  	ops
  	],{
  {"Process"->po_ProcessObject?(ProcessStatus[#, "Running"]&),r___}:>
   Set[
    $PySessions[name],
    Association@
   	 Join[
	     {
	      "Process"->po,
	      r,
	      "Name"->name
	      },
	     Thread[
	      {"SystemShell","VirtualEnvironment","Version","MetaInfo"}->
	       OptionValue[{"SystemShell","VirtualEnvironment","Version","MetaInfo"}]
	       ]
	     ]
	   ],
   _:>$Failed
  }]


Options[pySessionCreateProcessObject]=
	Options[PySessionStart]


Options[pySessionConfig]=
	Options[pySessionCreateProcessObject];
pySessionConfig[ops:OptionsPattern[]]:=
	Replace[Flatten@{OptionValue["PythonConfig"]},{
 	Except[{(_String|_?OptionQ)...}]:>{"i"}
 	}]
Options[shSessionConfig]=
	Options[pySessionCreateProcessObject]
shSessionConfig[ops:OptionsPattern[]]:=
	Replace[Flatten@{OptionValue["ShellConfig"]},{
 	Except[{(_String|_?OptionQ)...}]:>{}
 	}]


$pySessionPathExtension=
	Switch[$OperatingSystem,
		"MacOSX",
			StringRiffle[
				Append[""]@
				Join[
					{
						"/usr/local/bin"
						},
					FileNames[
						"bin",
						"/Library/Frameworks/Python.framework/Versions",
						2
						],
					FileNames[
						"bin",
						"/System/Library/Frameworks/Python.framework/Versions",
						2
						]
					],
				":"
				],
		_,
			""
		]


pySessionCreateProcessObject[
 {
	 Except[True] (* No shell *),
	 Except[_String] (* No venv *),
	 Except[_String] (* No version *)
	 }, 
 ops:OptionsPattern[]
 ]:=
 {
 	"Process"->
 		StartProcess[
 			Flatten@{
 				"python",
 				pySessionConfig[ops]
 				},
 			FilterRules[
 				{
 					ops,
 					If[$OperatingSystem=!="Windows",
 						ProcessEnvironment->
	 						<|
	 							"PATH"->$pySessionPathExtension<>Environment["PATH"]
	 							|>,
	 					Nothing
	 					]
 					},
	 			Options@StartProcess
	 			]
 		 ],
 	"Type"->"PythonInterpreter"
 	}


pySessionCreateProcessObject[
	{
		Except[True] (* No shell *),
		Except[_String] (* No venv *),
		s_String (* Use version *)
		}, 
	ops:OptionsPattern[]
	]:=
	{
		"Process"->
			StartProcess[
				Flatten@{
					If[StringMatchQ[s, NumberString], "python"<>s, s],
					pySessionConfig[ops]
					}, 
				FilterRules[{
					ops,
					If[$OperatingSystem=!="Windows",
 						ProcessEnvironment->
	 						<|
	 							"PATH"->
	 								$pySessionPathExtension<>Environment["PATH"]
	 							|>,
	 					Nothing
	 					]},
 				 Options@StartProcess
	 			 ]
 			],
		"Type"->"PythonInterpreter"
		}


pySessionCreateProcessObject[
 {
	 True (* Use shell *),
	 Except[_String] (* No venv *),
	 _ (* Ignore version *)
	 }, 
 ops:OptionsPattern[]
 ]:=
 {
 	"Process"->
 		StartProcess[Flatten@{
 			$SystemShell,
 			shSessionConfig[ops]
 			}, 
 			FilterRules[{
 				ops,
 				If[$OperatingSystem=!="Windows",
 					ProcessEnvironment->
 						<|
 							"PATH"->
 								$pySessionPathExtension<>Environment["PATH"]
 							|>,
 					Nothing
 					]
	 			},
 				Options@StartProcess
 				]
 			],
 	"Type"->"SystemShell"
 	}


pySessionCreateProcessObject[
 {
 	True (* Use shell *),
	 s_String (* Use venv *),
	 Except[_String] (* No version *)
	 }, 
 ops:OptionsPattern[]
 ]:=
 Replace[VenvDir[s],
 	{
  	d_String:>
  		{
  			"Process"->
  				With[
	  				{
		  				po = 
		  					StartProcess[Flatten@{
 								$SystemShell,
 								shSessionConfig[ops]
					 			}, 
					 			FilterRules[{ops},
					 				Options@StartProcess
					 				]
								]
		  				},
		  			WriteLine[po,
		  				StringRiffle[{
		  					"_dir=${PWD}",
		  					"cd "<>d,
		  					"source bin/activate",
		  					"cd $_dir"
		  					}]
		  				];
		  			po
		  			],
 			"Type"->"SystemShell"
 			}
  	}]


pySessionCreateProcessObject[
 {
	 False (* Use shell *),
	 s_String (* Use venv *),
	 Except[_String] (* No version *)
	 }, 
 ops:OptionsPattern[]
 ]:=
 {
 	"Process"->
	 	With[{ po = pySessionCreateProcessObject[True, s, None, ops]},
	 		WriteLine[po, "python"];
		 	po
		 	],
	"Type"->"PythonInterpreter"
	}


pySessionCreateProcessObject[
 {
	 False (* Use shell *),
	 s_String (* Use venv *),
	 v_String (* Use version *)
	 }, 
 ops:OptionsPattern[]
 ]:=
 {
 	"Process"->
		 With[{ po = pySessionCreateProcessObject[True, s, None, ops]},
		 	WriteLine[po, If[StringMatchQ[v, NumberString], "python"<>v, v]<>" -i"];
		 	po
		 	],
 	"Type"->"PythonInterpreter"
 	}


PySessionKill[name_]:=
	KillProcess@PySessionProcess[name]


PySessionRemove[name_]:=
	(
		PySessionKill[name];
		$PySessions[name]=.
		)


PySession[n_]:=
	Replace[$PySessions[n],Except[_Association]->None]


PySessionProcess[n_]:=
	Replace[PySession[n],a:Except[None]:>a["Process"]]


PySessionActive[n_]:=
	MatchQ[$PySessions[n]["Process"],_ProcessObject?(ProcessStatus[#,"Running"]&)];


PySessionType[n_]:=
	$PySessions[n]["Type"];


Clear[PySessionMeta];


PySessionMeta[n_]:=
	$PySessions[n]["MetaInfo"]


PySessionMeta/:
	HoldPattern[Set[PySessionMeta[n_],v_]]:=
		Set[$PySessions[n,"MetaInfo"],v];
PySessionMeta/:
	HoldPattern[Set[PySessionMeta[n_][p__],v_]]:=
		Set[$PySessions[n,"MetaInfo",p],v];


PySessionMeta/:
	HoldPattern[SetDelayed[PySessionMeta[n_],v_]]:=
		SetDelayed[$PySessions[n,"MetaInfo"],v];
PySessionMeta/:
	HoldPattern[SetDelayed[PySessionMeta[n_][p__],v_]]:=
		SetDelayed[$PySessions[n,"MetaInfo",p],v];


PySessionMeta/:
	HoldPattern[Unset[PySessionMeta[n_]]]:=
		Unset[$PySessions[n,"MetaInfo"]];
PySessionMeta/:
	HoldPattern[Unset[PySessionMeta[n_][p__]]]:=
		Unset[$PySessions[n,"MetaInfo",p]]


PySessionWrite[name_,s_String]:=
	WriteLine[PySessionProcess[name], s];
PySessionWrite[name_,l_List]:=
	PySessionWrite[name, PySessionWriteEscape[l]]


Clear[PySessionWriteEscape];
PySessionWriteEscape[s_String]:=
	s;
PySessionWriteEscape[File[f_String]]:=
	"\""<>ExpandFileName[f]<>"\"";
PySessionWriteEscape[URL[u_String]]:=
	"\""<>u<>"\"";
PySessionWriteEscape[l_List]:=
	StringRiffle@Map[PySessionWriteEscape,l]
PySessionWriteEscape[r_Rule]:=
	PySessionWriteEscape[First[r]]<>"--="<>PySessionWriteEscape[Last[r]];
PySessionWriteEscape[Break]:=
	"\n";
PySessionWriteEscape[e_]:=ToString[e];


PySessionRead[name_]:=
Catch@
	With[{proc=PySessionProcess[name]},
		If[!MatchQ[proc,_ProcessObject],Throw[$Failed]];
		AssociationMap[
			With[{strm=ProcessConnection[proc,#]},
				If[!MatchQ[strm,_InputStream],Throw[$Failed]];
				ReadString[ProcessConnection[PySessionProcess[name],#],EndOfBuffer]
				]&,
			{
				"StandardOutput",
				"StandardError"
				}
			]
		];


Options[PySessionRun]=
	{
		TimeConstraint->Automatic,
		"PollTime"->Automatic,
		Monitor->False,
		"CleanOutput"->True,
		"WaitFor"->Automatic
		};
PySessionRun[name_?(PySessionType[#]==="PythonInterpreter"&),
 s:_String|_List,
 ops:OptionsPattern[]
 ]:=
 PySessionRunPython[name,s,ops];
PySessionRun[name_?(PySessionType[#]==="SystemShell"&),
 s:_String|_List,
 ops:OptionsPattern[]
 ]:=
 PySessionRunShell[name,s,ops]


Options[PySessionRunCore]=
	Options[PySessionRun];
PySessionRunCore[
	name_,
	cmdFunction_,
	cleanFunction_,
	ops:OptionsPattern[]
	]:=
	Catch@
	Block[{
		poll=
			Replace[OptionValue["PollTime"],
				Except[_?NumericQ]->.01
				],
		reads,
		readDone,
		readStep,
		startflag=CreateUUID["process-start-"],
		doneflag=CreateUUID["process-"],
		mon = TrueQ[OptionValue[Monitor]]
		},
		Function[
			Null,
			If[mon,
				Monitor[#,
			  	Internal`LoadingPanel@
			  		Grid[
				  		KeyValueMap[
								{#,
									If[OptionValue["CleanOutput"]//TrueQ,
										cleanFunction[##,startflag,doneflag],
										#2
										]}&,
								reads
								],
							Alignment->{Left,Top}
							]
					],
			 #
			 ],
			HoldAllComplete
			]@
		Quiet@WriteLine[PySessionProcess@name, cmdFunction[startflag, doneflag]];
		Pause[poll];
		reads=Replace[PySessionRead[name],$Failed:>Throw[$Failed]];
		readStep[]:=
			reads=
				Merge[
					{
						reads,
						Replace[PySessionRead[name],$Failed:>Throw[$Failed]]
						},
					StringJoin
					];
		readDone[recurse_:True]:=
			Switch[OptionValue["WaitFor"],
				All,
					AllTrue[Values[reads],StringContainsQ[doneflag]],
				"StandardError",
					StringContainsQ[doneflag]@reads["StandardError"],
				"StandardOutput",
					StringContainsQ[doneflag]@reads["StandardOutput"],
				Automatic,
					With[{ct=StringCount[StringRiffle[Values[reads]],doneflag]},
						ct==2||
						(ct==1&&
							recurse&&
								TimeConstrained[
									poll=.01;
									While[!readDone[False],Pause[poll];readStep[]],
									1,
									True
									]
							)
						]
				];
		With[{
			ctraint=
				Replace[OptionValue[TimeConstraint],
					Except[_?NumericQ|None]->1
					]
			},
			If[ctraint=!=None,
				TimeConstrained[
					While[!readDone[],Pause[poll];readStep[]],
					ctraint,
					readStep[]
					],
				While[!readDone[],Pause[poll];readStep[]]
				]
			];
		KeyValueMap[
			#->
				If[OptionValue["CleanOutput"]//TrueQ,
					cleanFunction[##,startflag,doneflag],
					#2
					]&,
			reads
			]//Association
		];


$pyLoadInterpreterString=
	"Type \"help\", \"copyright\", \"credits\" or \"license\" for more information.";


pyCleanRetStrings[par_,str_,startflag_,doneflag_]:=
	If[par==="StandardError",
		Function[
			StringDelete[#,
				Repeated[">>>"~~" "|""]|
				Repeated["..."~~" "|""]
				]
			],
		Identity
		][
		StringTrim[
			First@StringSplit[
				Last@
					Replace[StringSplit[str,startflag,2],
						{s_}:>StringSplit[s, $pyLoadInterpreterString, 2]
						],
				doneflag,
				2
				],
			("\n"|""~~startflag)|
			(doneflag~~"\n"|"")|
			(StartOfString~~"\n")|
			("\n"~~EndOfString)
			]
		];


Options[PySessionRunPython]=
 Options[PySessionRun];
PySessionRunPython[name_,
 s:_String|_List,ops:OptionsPattern[]]:=
 PySessionRunCore[
 	name,
 	StringRiffle[
		{
			"import sys",
			"from __future__ import print_function",
			"print('"<>#<>"')",
			"print('"<>#<>"', file=sys.stderr)",
			"#-----Start Block------\n",
			s,
			"\n#-----End Block------",
			"print('"<>#2<>"', file=sys.stderr)",
			"print('"<>#2<>"')"
			},
		"\n"
		]&,
	pyCleanRetStrings,
	ops
	];


shCleanRetStrings[par_,str_,startflag_,doneflag_]:=
	StringTrim[
		First@StringSplit[
			Last@StringSplit[str,startflag,2],
			doneflag,
			2
			],
	(StartOfString~~"\n")|
	("\n"~~EndOfString)|
		startflag|
		doneflag
	]


Options[PySessionRunShell]=
 Options[PySessionRun];
PySessionRunShell[name_,
 s:_String|_List,
 ops:OptionsPattern[]
 ]:=
 PySessionRunCore[
 	name,
 	StringRiffle[
		{
		 "echo \""<>#<>"\"",
		 ">&2 echo \""<>#<>"\"",
		 s,
		 ">&2 echo \""<>#2<>"\"",
		 "echo \""<>#2<>"\""
		 },
		"\n"
		]&,
	shCleanRetStrings,
	ops
	];


End[];



