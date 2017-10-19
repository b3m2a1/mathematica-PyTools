
image_importer(i_dict):
    from PIL import Image
    import io
    if i_dict["ImportFormat"] == "File":
        img = Image.open(i_dict["ImportValue"])
    else:
        bytebuff = io.BytesIO(i_dict["ImportValue"])
        img = Image.open(bytebuff, format=i_dict["ImportDataFormat"] )
    return img


mathematica_register_type_importer["Image", image_importer]
