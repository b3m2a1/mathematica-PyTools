(* ::Package:: *)



PyRun::usage=
	"Runs python code and returns a string of the result";
PyInstall::usage=
	"Runs pip to install a package";


PackageScopeBlock[
	$PyRunLastCompiled;
	PyRunSession::usage="Session used by PyRun";
	PyRunSessionBuildName::usage="Session name used by PyRun";
	];


Begin["`Private`"];


Options[PyRun]=
	Join[
		{
			"SessionName"->Automatic,
			"UseSession"->False,
			"KillSession"->False,
			"EchoCode"->False,
			"PrintTraceback"->True,
			"PrintStdErr"->True,
			"ParseOutput"->True
			},
		Options[PySessionStart],
		Options[PySessionRun]
		];


PyRunSessionBuildName[{sh_,v_,venv_}]:=
	StringRiffle[{
		If[TrueQ@sh,
			"sh",
			"python"
			],
		If[!StringQ@v,"default",v],
		If[!StringQ@venv,"none",venv]
		},
		"-"
		]


Options[PyRunSession]=
	Join[
		Options[PyRun],
		{
			"MakeSession"->False
			}
		];
PyRunSession[ops:OptionsPattern[]]:=
	With[{params=
		AssociationThread[
			{"SessionName","SystemShell","Version","VirtualEnvironment"},
			OptionValue[{"SessionName","SystemShell","Version","VirtualEnvironment"}]
			]},	
		Replace[PySession@params["SessionName"],
			None:>
				Replace[
					PySession@
					PyRunSessionBuildName[
						Lookup[params, {"SystemShell","Version","VirtualEnvironment"}]
						],
					None:>
						If[OptionValue["MakeSession"]//TrueQ,
							PySessionStart[
								Replace[params["SessionName"],
									Automatic:>
										PyRunSessionBuildName[
											Lookup[params, 
												{"SystemShell","Version","VirtualEnvironment"}
												]
											]
									],
								FilterRules[{ops},	
									Options[PySessionStart]
									]
								],
							None
							]
					]
			]
		]


PyRun~SetAttributes~HoldFirst;


PyRun::shstr="SystemShell sessions require string input";


PyRun::stderr="``";
PyRun::tb="``";


PyRun[code_,
	ops:OptionsPattern[]
	]:=
	Catch@
	Block[{$eMExport},
		With[
			{sesh=
				If[TrueQ@OptionValue["UseSession"],
					PyRunSession[ops,
						"MakeSession"->True
						],
					PySessionStart[
						CreateUUID["python-session-"],
						FilterRules[{ops}, Options[PySessionStart]]
						]
					]
				},
			If[sesh===$Failed, Throw[sesh]];
			Function[
				If[!TrueQ@OptionValue["UseSession"]||TrueQ@OptionValue["KillSession"],
					PySessionRemove[sesh["Name"]]
					];
				#
				]@
			If[sesh["SystemShell"]//TrueQ,
				If[StringQ[code],
					With[{
						r=
							iPyRun[Verbatim[code],
								sesh,
								ops
								]
						},
						If[TrueQ@OptionValue["PrintStdErr"],
							If[StringLength[r["StandardError"]]>0,
								Message[PyRun::stderr, r["StandardError"]]
								];
							r["StandardOutput"]//If[StringLength[#]>0,#,Null]&,
							r
							]
						],
					Message[PyRun::shstr];
					$Failed
					],
				With[{r=iPyRun[code,sesh,ops]},
					If[TrueQ@OptionValue["PrintTraceback"],
						If[StringLength[r["StandardError"]]>0,
							Message[PyRun::tb, StringTrim@r["StandardError"]]
							];
						If[OptionValue["ParseOutput"]&&$eMExport//TrueQ,
							r["StandardOutput"]//PyMExportParse,
							r["StandardOutput"]//If[StringLength[#]>0,#,Null]&
							],
						If[OptionValue["ParseOutput"]&&$eMExport//TrueQ,
							ReplacePart[r,
								"StandardOutput"->
									PyMExportParse[r["StandardOutput"]]
								],
							r
							]
						]
					]
				]
			]
		]


Options[iPyRun]=
	Options[PyRun]


iPyRun~SetAttributes~HoldFirst


iPyRun[Verbatim[Verbatim][code:_String|_List],
	sesh_,
	ops:OptionsPattern[]
	]:=
	PySessionRun[sesh["Name"],
		code,
		FilterRules[{ops}, Options[PySessionRun]]
		]


PyRun::nocomp="Couldn't compile `` to python code";


iPyRunCompilePrepDefer~SetAttributes~HoldAllComplete;


iPyRunCompilePrep[code_]:=
	ToSymbolicPython@@
	Replace[Hold[expr_]:>
		With[{ph=$PyRunHeader},
			Hold[ph;expr]
			]
		]@
	ReplaceAll[
		iPyRunCompilePrepDefer[e_]:>e
		]@
	ReplaceAll[
		Replace[Hold[code],{
			Hold[Return[a_]]:>
				Hold[PyMExport[a]],
			Hold[CompoundExpression[e___,Return[a_]]]:>
				Hold[CompoundExpression[e,PyMExport[a]]]
			}],{
				PyMExport[a_]:>
					RuleCondition[
						$eMExport=True;
						iPyRunCompilePrepDefer@
							PyCall[PyDot["MLib","mathematica_export"]][a],
						True
						],
				PyMScript[s_][a___]:>
					PyCall[
						PyCall[PyDot["MLib","mathematica_script"]][s],
						a
						]
			}
		];
iPyRunCompilePrep~SetAttributes~HoldFirst


iPyRun[code_,
	sesh_,
	ops:OptionsPattern[]
	]:=
		With[{
			vs=ToPython@iPyRunCompilePrep[code]
			},
			$PyRunLastCompiled=vs;
			If[StringQ@vs,
				If[TrueQ@OptionValue["EchoCode"],
					Echo[vs];
					];
				iPyRun[Verbatim[vs],
					sesh,
					ops
					],
				Message[PyRun::nocomp, 
					FirstCase[Hold[code],
						e:Except[_String]:>HoldForm[e],
						HoldForm[code],
						{1,\[Infinity]}
						]
					];
				$Failed
				]
			];


Options[PyInstall]=
	Join[
		Options[PyRun],
		{
			"SuperUser"->False,
			"Upgrade"->False
			}
		];
PyInstall[pkg_, ops:OptionsPattern[]]:=
	With[{
		suinfo=
			Replace[OptionValue["SuperUser"], {
				True -> {"", ""},
				s_String :> {s, ""},
				su:{_String, _String}:>su,
				_->{None, ""}
				}]
			},
		PyRun[
			Evaluate[
				StringTrim@
				StringRiffle[{
					If[StringQ[suinfo[[1]]],
						Switch[$OperatingSystem,
							"MacOSX",
								"su -l "<>suinfo[[1]]<>"\n '"<>#<>"'",
							_,
								"su -c "<>"'"<>#<>"'"
							],
							#]&@
					"pip"<>
						Replace[OptionValue["Version"],{
							s_String?(StringMatchQ[NumberString]):>s,
							n_?NumberQ:>ToString[n],
							_->""
							}]<>
						" install "<>If[OptionValue["Upgrade"]//TrueQ,"--upgrade ",""]<>pkg,
					If[StringQ[suinfo[[2]]],suinfo[[2]],""]
					},
					"\n"
					]
				],
			FilterRules[
				{
					ops,
					"SystemShell"->True,
					"WaitFor"->All,
					TimeConstraint->None
					},
				Options[PyRun]
				]
			]
		]


End[];



