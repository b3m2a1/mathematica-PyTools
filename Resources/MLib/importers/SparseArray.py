
matrix_importer(sparse_dict):
    import scipy
    if i_dict["ImportFormat"] == "File":
        try:
            sparse_array = scipy.sparse.io.mmread(sparse_dict["ImportValue"])
        finally:
            sparse_file.close()
    else:
        import tempfile as tmp
        raise Exception("String based matrix currently unsupported")
        sparse_array = sparse.io.mmread(sparse_dict["ImportValue"])
    return sparse_array


mathematica_register_type_importer["Matrix", sparse_array_importer]
