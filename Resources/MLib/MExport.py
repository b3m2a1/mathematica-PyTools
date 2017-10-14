"""This defines a quick I/O framework for sending to Mathematica

"""

from __future__ import print_function

mathematica_type_exporters = {}
mathematica_export_parameters = {
    "BufferMaxSize" : 5000
} #These are set on the Mathematica side

def mathematica_safe_json(obj):

  import json

  try:
    m_string = json.dumps(obj)
  except TypeError:
    m_string = repr(obj)

  return m_string

def mathematica_default_export(obj):
  return { "ReturnType":"String", "ReturnValue":mathematica_safe_json(obj) }

def mathematica_register_type_exporter(t, f):
  mathematica_type_exporters[t] = f;

def mathematica_export(obj):
  import json

  m_typ = type(obj)
  exp_function = mathematica_type_exporters[m_typ] if m_typ in mathematica_type_exporters else mathematica_default_export
  exp_data =  exp_function(obj)
  if isinstance(exp_data, str):
    m_dict = {
      "ReturnType":"String",
      "ReturnValue":exp_data
      }
  elif isinstance(exp_data, dict):
    if "ReturnValue" in exp_data:
      m_dict= exp_data
    else:
      m_dict = {
        "ReturnType":"String",
        "ReturnValue":mathematica_safe_json(exp_data)
        }
  else:
    m_dict = {
      "ReturnType":"String",
      "ReturnValue":mathematica_safe_json(exp_data)
      }

  print(mathematica_export_parameters["Delimiter"])
  if len(m_dict["ReturnValue"]) > mathematica_export_parameters["BufferMaxSize"]:
      import tempfile as tmp
      dump_tmp = tmp.NamedTemporaryFile(delete=False)
      dump_f = dump_tmp.name
      dump_tmp.close()
      try:
          tmp_f = open(dump_f, "w")
          tmp_f.write(m_dict["ReturnValue"])
      finally:
          tmp_f.close()
      m_dict["ReturnValue"] = dump_f
      m_dict["ReturnType"] = "TemporaryFile"
  print(json.dumps(m_dict))
  print(mathematica_export_parameters["Delimiter"])
