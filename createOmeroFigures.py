
from omero.gateway import BlitzGateway
from omeroweb.webgateway.marshal import imageMarshal
import json
from cStringIO import StringIO
import omero
from omero.rtypes import wrap, rlong
from omero.gateway import OriginalFileWrapper

conn = BlitzGateway("user-1", "ome", host="eel.openmicroscopy.org", port=4064)
conn.connect()


image_ids = [71852]

JSON_FILEANN_NS = "omero.web.figure.json"


def create_figure_file(figure_json):

    figure_name = figure_json['figureName']
    if len(figure_json['panels']) == 0:
        raise Exception('No Panels')
    first_img_id = figure_json['panels'][0]['imageId']

    # we store json in description field...
    description = {}
    description['name'] = figure_name
    description['imageId'] = first_img_id

    # Try to set Group context to the same as first image
    conn.SERVICE_OPTS.setOmeroGroup('-1')
    i = conn.getObject("Image", first_img_id)
    gid = i.getDetails().getGroup().getId()
    conn.SERVICE_OPTS.setOmeroGroup(gid)

    json_string = json.dumps(figure_json)
    file_size = len(json_string)
    f = StringIO()
    # f.write(figure_json)
    json.dump(figure_json, f)

    update = conn.getUpdateService()
    orig_file = create_original_file_from_file_obj(
        f, '', figure_name, file_size, mimetype="application/json")
    fa = omero.model.FileAnnotationI()
    fa.setFile(omero.model.OriginalFileI(orig_file.getId(), False))
    fa.setNs(wrap(JSON_FILEANN_NS))
    desc = json.dumps(description)
    fa.setDescription(wrap(desc))
    fa = update.saveAndReturnObject(fa, conn.SERVICE_OPTS)
    file_id = fa.getId().getValue()
    print "Figure Created", file_id


def create_original_file_from_file_obj(fo, path, name, file_size, mimetype=None):
    """
    This is a copy of the same method from Blitz Gateway, but fixes a bug
    where the conn.SERVICE_OPTS are not passed in the API calls.
    Once this is fixed in OMERO-5 (and we don't need to work with OMERO-4)
    then we can revert to using the BlitzGateway for this method again.
    """
    raw_file_store = conn.createRawFileStore()

    # create original file, set name, path, mimetype
    original_file = omero.model.OriginalFileI()
    original_file.setName(wrap(name))
    original_file.setPath(wrap(path))
    if mimetype:
        original_file.mimetype = wrap(mimetype)
    original_file.setSize(rlong(file_size))
    # set sha1  # ONLY for OMERO-4
    try:
        import hashlib
        hash_sha1 = hashlib.sha1
    except:
        import sha
        hash_sha1 = sha.new
    try:
        fo.seek(0)
        h = hash_sha1()
        h.update(fo.read())
        original_file.setSha1(wrap(h.hexdigest()))
    except:
        pass       # OMERO-5 doesn't need this
    upd = conn.getUpdateService()
    original_file = upd.saveAndReturnObject(original_file, conn.SERVICE_OPTS)

    # upload file
    fo.seek(0)
    raw_file_store.setFileId(original_file.getId().getValue(),
                             conn.SERVICE_OPTS)
    buf = 10000
    for pos in range(0, long(file_size), buf):
        block = None
        if file_size-pos < buf:
            block_size = file_size-pos
        else:
            block_size = buf
        fo.seek(pos)
        block = fo.read(block_size)
        raw_file_store.write(block, pos, block_size, conn.SERVICE_OPTS)
    # https://github.com/openmicroscopy/openmicroscopy/pull/2006
    original_file = raw_file_store.save(conn.SERVICE_OPTS)
    raw_file_store.close()
    return OriginalFileWrapper(conn, original_file)


def get_panel_json(image_id, x, y, width, height, theZ, channel=None):

    image = conn.getObject('Image', image_id)
    # px = image.getPrimaryPixels().getPhysicalSizeX()
    # py = image.getPrimaryPixels().getPhysicalSizeY()

    rv = imageMarshal(image)

    if channel is not None:
        for idx, ch in enumerate(rv['channels']):
            ch['active'] = idx == channel
            # print ch['color']
            ch['color'] = 'ffffff'

    img_json = {
        "labels":[],
        "height": height,
        "channels": rv['channels'],
        # "deltaT":[],
        # "selected":true,
        "width": width,
        # "pixel_size_x": px.getValue(),
        # "pixel_size_x_unit": str(px.getUnit()),
        # "pixel_size_x_symbol": px.getSymbol(),
        # "pixel_size_y": py.getValue(),
        "sizeT": rv['size']['t'],
        "sizeZ": rv['size']['z'],
        "dx":0,
        "dy":0,
        "rotation":0,
        "imageId":image_id,
        # "datasetId":1301,
        # "datasetName":"CENPB-siRNAi",
        "name":"438CTR_01_5_R3D_D3D.dv",
        "orig_width": rv['size']['width'],
        "zoom":100,
        "shapes":[],
        "orig_height": rv['size']['height'],
        "theZ": theZ,
        "y": y,
        "x": x,
        "theT": rv['rdefs']['defaultT']
    }
    return img_json


def get_labels_json(panel_json, column, row):

    labels = []

    channels = panel_json['channels']
    if row == 0:
        labels.append({"text":channels[column]['label'],
                       "size":14,
                       "position":"top",
                       "color":"000000"
                     })
    if column == 0:
        labels.append({"text": "field %s" % row,
                       "size":14,
                       "position":"leftvert",
                       "color":"000000"
                     })
    return labels

figure_json = {"version":2,
               "paper_width":595,
               "paper_height":842,
               "page_size":"A4",
               # "page_count":"1",
               # "paper_spacing":50,
               # "page_col_count":"1",
               # "height_mm":297,
               # "width_mm":210,
               # "orientation":"vertical",
               # "legend":"",
               # "legend_collapsed":true,
               "figureName":"from script",
               # "fileId":32351
               }

width = 200
height = 100
spacing = width/20

curr_x = 0
curr_y = 0
panels_json = []
column_count = 2

image_id = 71852
image = conn.getObject('image', image_id)


for c in range(image.getSizeC()):
    curr_x = c * (width + spacing)
    for z in range(image.getSizeZ()):
        curr_y = z * (height + spacing)
        j = get_panel_json(image_id, curr_x, curr_y, width, height, z, c)
        j['labels'] = get_labels_json(j, c, z)
        panels_json.append(j)


figure_json['panels'] = panels_json

create_figure_file(figure_json)

conn.close()

