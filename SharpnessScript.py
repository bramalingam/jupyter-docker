from PIL import Image
import numpy as np

from omero.gateway import BlitzGateway
# from Parse_OMERO_Properties import USERNAME, PASSWORD, HOST, PORT
# from Parse_OMERO_Properties import datasetId, imageId, plateId

if __name__ == '__main__':
    
    USERNAME = ""
    PASSWORD = ""
    HOST = ""
    PORT = 
    plateId = 

    conn = BlitzGateway(USERNAME, PASSWORD, host=HOST, port=PORT)
    conn.connect()
    print USERNAME

    user = conn.getUser()
    print ("Current user:")
    print ("   ID:", user.getId())
    print ("   Username:", user.getName())
    print ("   Full Name:", user.getFullName())
    # Using secure connection.
    # By default, once we have logged in, data transfer is not encrypted
    # (faster)
    # To use a secure connection, call setSecure(True):
    conn.setSecure(True);

    plate = conn.getObject("Plate", plateId)
    print "\nNumber of fields:", plate.getNumberOfFields()
    print "\nGrid size:", plate.getGridSize()
    print "\nWells in Plate:", plate.getName()
    for well in plate.listChildren():
        index = well.countWellSample()
        print "  Well: ", well.row, well.column, " Fields:", index
        for index in xrange(0, index):
                pixels = well.getImage(index).getPrimaryPixels()
                plane = pixels.getPlane(0, 0, 0)
                gy, gx = np.gradient(plane)
                gnorm = np.sqrt(gx**2 + gy**2)
                sharpness = np.average(gnorm)
                print "\n,Sharpness Score:", sharpness