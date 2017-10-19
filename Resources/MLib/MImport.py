"""This defines a quick I/O framework for importing from Mathematica

"""

from __future__ import print_function
import os

mathematica_type_importers = {}

def mathematica_default_import(i_dict):
  return i_dict["ImportValue"]

def mathematica_register_type_importer(t, f):
  mathematica_type_importers[t] = f

mathematica_importer_dir = os.path.join(os.path.dirname(__file__), "importers")
def mathematica_load_importer(m_typ):
    if m_typ not in mathematica_type_importers:
        m_path = os.path.join(
                mathematica_importer_dir,
                m_typ+".py"
                );
        if os.path.exists( m_path ):
            try:
                imp_file = open(m_path)
                exec(imp_file.read())
            finally:
                imp_file.close()
    if m_typ in mathematica_type_importers:
        m_importer = mathematica_type_importers[m_typ]
    else:
        m_importer = mathematica_default_import

    return m_importer

def _mathematica_import_core(i_dict):
    imp = mathematica_load_importer(i_dict["ImportType"])
    return imp(i_dict)

def mathematica_import(i_dict):
  imp_data =  _mathematica_import_core(i_dict)
  return imp_data
