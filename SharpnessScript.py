from PIL import Image
import numpy as np
import matplotlib
import matplotlib.pyplot as plt
import decimal
import seaborn as sns
from mpl_toolkits.axes_grid1 import AxesGrid
from numpy import array, int8

from omero.gateway import BlitzGateway
# from Parse_OMERO_Properties import USERNAME, PASSWORD, HOST, PORT
# from Parse_OMERO_Properties import datasetId, imageId, plateId

if __name__ == '__main__':

    def planeGen():
        """generator will yield planes"""
        for p in planes:
            yield p
    
    USERNAME = ""
    PASSWORD = ""
    HOST = ""
    PORT = 
    plateId = 

    conn = BlitzGateway(USERNAME, PASSWORD, host=HOST, port=PORT)
    conn.connect()
    conn.setSecure(True);

    plate = conn.getObject("Plate", plateId)
    print "\nNumber of fields:", plate.getNumberOfFields()
    print "\nGrid size:", plate.getGridSize()
    print "\nWells in Plate:", plate.getName()

    plate_name = plate.getName()
    size_z = plate.getNumberOfFields()
    size_t = 1
    cntr=0
    for well in plate.listChildren():
        index = well.countWellSample()
        print "  Well: ", well.row, well.column, " Fields:", index        
        #Hack for writing it into an image, will be used for making omero.figures (split-view) in an automated manner 
        size_z = index

        for index in xrange(0, index):
                pixels = well.getImage(index).getPrimaryPixels()
                size_c = well.getImage(index).getSizeC();
                if cntr==0:
                    result_array = np.zeros((96,4*size_c), dtype=int);
                for ch in xrange(0, size_c):
                    plane = pixels.getPlane(0, ch, 0)
                    gy, gx = np.gradient(plane)
                    gnorm = np.sqrt(gx**2 + gy**2)
                    sharpness = np.average(gnorm)
                    result_array[((well.row)*12)+well.column,(index+ch*4)]=sharpness;
                    cntr=cntr+1;
    print result_array
  
    # #Binary data
    # np.save('maximums.npy', result_array)
    result_array = np.load('maximums.npy')
    vals=[]
    planes=[]
    for colval in range (0, result_array.shape[1]):
        data = result_array[:,colval].reshape(8,12);
        data = np.repeat(data, 20, axis=1)
        data = np.repeat(data, 20, axis=0)
        planes.append(np.uint16(data))
        ax = plt.subplot(4,4,colval+1)
        plt.pcolor(data)
        plt.axis('off')
        plt.colorbar()
        ax.title.set_text(colval)
    savefig(plate_name + 'SharpnessHeatMaps.png')
    plt.show()
    # print planes

    desc = "Image created from a hard-coded arrays"
    i = conn.createImageFromNumpySeq(
    planeGen(), plate_name + "numpy image", size_z, size_c, size_t, description=desc,
    dataset=None)
    print 'Created new Image:%s Name:"%s"' % (i.getId(), i.getName())
    conn.close()
