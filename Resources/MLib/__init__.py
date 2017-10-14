"""
This defines the MScript package which implements scripts for working
with the Mathematica-python process interface

The core classes in this package are:

MathematicaScript - a class for loading scripts

The core functions in the package are:

mathematica_script - a cached script loader
mathematica_export - an export system


"""

from .MExport import *
from .MScript import *
