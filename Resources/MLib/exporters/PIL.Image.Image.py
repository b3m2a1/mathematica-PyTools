from PIL import Image

def pil_image_export(img):
    import io

    dims = img.size
    fmt = img.format if img.format is not None else "PNG"

    if dims[0] * dims[1] > 5000:
        import tempfile as tmp
        dump_tmp = tmp.NamedTemporaryFile(delete=False)
        dump_f = dump_tmp.name
        dump_tmp.close()
        img.save(dump_f, format = fmt)
        core_data = {
            "ReturnType"   : "TemporaryFile",
            "ReturnValue"  : dump_f,
            "ReturnFormat" : fmt
            }
    else:
        imgBuff = io.BytesIO()
        img.save(imgBuff, format = fmt)
        core_data = {
            "ReturnType"  : "Bytes",
            "ReturnValue" : imgBuff.getvalue(),
            "ReturnFormat": fmt
            }

    return core_data

mathematica_register_type_exporter(Image.Image, pil_image_export)
