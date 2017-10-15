import numpy

def numpy_ndarray_export(arr):
    return {
        "ReturnType":"String",
        "ReturnValue":str(arr.tolist()),
        }

mathematica_register_type_exporter(numpy.ndarray, numpy_ndarray_export)
