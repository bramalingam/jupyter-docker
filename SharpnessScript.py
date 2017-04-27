from PIL import Image
import numpy as np
import matplotlib
import matplotlib.pyplot as plt
import decimal
import seaborn as sns
from mpl_toolkits.axes_grid1 import AxesGrid

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
    # Using secure connection.
    # By default, once we have logged in, data transfer is not encrypted
    # (faster)
    # To use a secure connection, call setSecure(True):
    conn.setSecure(True);

    plate = conn.getObject("Plate", plateId)
    print "\nNumber of fields:", plate.getNumberOfFields()
    print "\nGrid size:", plate.getGridSize()
    print "\nWells in Plate:", plate.getName()
    cntr=0
    for well in plate.listChildren():
        index = well.countWellSample()
        print "  Well: ", well.row, well.column, " Fields:", index
        for index in xrange(0, index):
                pixels = well.getImage(index).getPrimaryPixels()
                channels = well.getImage(index).getSizeC();
                if cntr==0:
                    result_array = np.zeros((96,4*channels), dtype=int);
                for ch in xrange(0, channels):
                    plane = pixels.getPlane(0, ch, 0)
                    gy, gx = np.gradient(plane)
                    gnorm = np.sqrt(gx**2 + gy**2)
                    sharpness = np.average(gnorm)
                    print "\n,Sharpness Score:", sharpness
                    print ((well.row)*12)+well.column
                    result_array[((well.row)*12)+well.column,(index+ch*4)]=sharpness;
                    cntr=cntr+1;
    print result_array
   
    # #Binary data
    np.save('maximums.npy', result_array)
    result_array = np.load('maximums.npy')
    vals=[]
    for colval in range (0, result_array.shape[1]):
        data = result_array[:,colval].reshape(8,12);
        ax = plt.subplot(4,4,colval+1)
        plt.pcolor(data)
        plt.axis('off')
        plt.colorbar()
        ax.title.set_text(colval)
    plt.show()

    # Secondary Representations
     # plt.imshow(result_array, cmap=matplotlib.cm.Reds, vmin=np.min(result_array[np.nonzero(result_array)])-100, vmax=np.max(result_array[np.nonzero(result_array)])+100)


    # # get the tick label font size
    # fontsize_pt = plt.rcParams['ytick.labelsize']
    # dpi = 72.27
    # # compute the matrix height in points and inches
    # matrix_height_pt = fontsize_pt * data.shape[0]
    # matrix_height_in = matrix_height_pt / dpi

    # # compute the required figure height 
    # top_margin = 0.04  # in percentage of the figure height
    # bottom_margin = 0.04 # in percentage of the figure height
    # figure_height = matrix_height_in / (1 - top_margin - bottom_margin)

    # # build the figure instance with the desired height
    # fig, ax = plt.subplots(
    #         figsize=(6,figure_height), 
    #         gridspec_kw=dict(top=1-top_margin, bottom=bottom_margin))

    # # let seaborn do it's thing
    # ax = sns.heatmap(data, ax=ax)
    # # save the figure
    # plt.savefig('test.png')
