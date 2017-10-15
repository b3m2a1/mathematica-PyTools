"""This defines a quick I/O framework for sending to Mathematica

"""

from __future__ import print_function
import os

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
  import base64
  if isinstance(obj, bytes):
      exp_data = {
        "ReturnType":"Bytes",
        "ReturnValue":str(base64.b64encode(obj))
        }
  else:
      exp_data = { "ReturnType":"String", "ReturnValue":mathematica_safe_json(obj) }
  return exp_data

def mathematica_register_type_exporter(t, f):
  mathematica_type_exporters[t] = f;

mathematica_exporter_dir = os.path.join(os.path.dirname(__file__), "exporters")
def mathematica_load_exporter(obj):
    m_typ = type(obj)
    obj_mod = m_typ.__module__ + "." if hasattr(m_typ, "__module__") else ""
    obj_name = m_typ.__name__
    if m_typ not in mathematica_type_exporters:
        m_path = os.path.join(
                mathematica_exporter_dir,
                obj_mod + obj_name +".py"
                );
        if not os.path.exists(m_path) and len(obj_mod) > 0:
            m_path= os.path.join(
                    mathematica_exporter_dir,
                    obj_mod + "py"
                    );
        if os.path.exists( m_path ):
            try:
                exp_file = open(m_path)
                exec(exp_file.read())
            finally:
                exp_file.close()
    if m_typ in mathematica_type_exporters:
        m_exporter = mathematica_type_exporters[m_typ]
    else:
        m_exporter = mathematica_default_export

    return m_exporter

def _mathematica_export_core(obj):
    exp = mathematica_load_exporter(obj)
    return exp(obj)

def mathematica_export(obj):
  import json

  exp_data =  _mathematica_export_core(obj)
  if isinstance(exp_data, str):
    m_dict = {
      "ReturnType":"String",
      "ReturnValue":exp_data
      }
  elif isinstance(exp_data, bytes):
    import base64
    m_dict = {
      "ReturnType": "Bytes",
      "ReturnValue": str(base64.b64encode(exp_data))
      }
  elif isinstance(exp_data, dict):
    if "ReturnValue" in exp_data:
      m_dict = exp_data
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

  if isinstance(m_dict["ReturnValue"], bytes):
      import base64
      m_dict["ReturnType"] = "Bytes"
      m_dict["ReturnValue"] = str(base64.b64encode(m_dict["ReturnValue"]))
  elif not isinstance(m_dict["ReturnValue"], str):
      m_dict["ReturnValue"] = mathematica_safe_json(m_dict["ReturnValue"])

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
