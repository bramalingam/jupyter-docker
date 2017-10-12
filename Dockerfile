FROM jupyter/scipy-notebook@sha256:4825556416ec7dcf4df73585a71595d29a274ef7d6d7c97267606661f3466952
MAINTAINER ome-devel@lists.openmicroscopy.org.uk

USER root
RUN apt-get update -y && \
    apt-get install -y nodejs

RUN install -o jovyan -g users -d /notebooks /opt/omero

USER jovyan

RUN conda create -n python2 python=2 --quiet --yes
RUN /opt/conda/envs/python2/bin/pip install omego && \
    cd /opt/omero && \
    /opt/conda/envs/python2/bin/omego download --ice 3.6 server --release 5.3 --sym OMERO.server && \
    rm -f OMERO.server-*.zip && \
    echo /opt/omero/OMERO.server/lib/python > \
    /opt/conda/envs/python2/lib/python2.7/site-packages/omero.pth

RUN conda install --name python2 --quiet --yes \
    joblib \
    markdown \
    pytables \
    python-igraph

# RISE: "Live" Reveal.js Jupyter/IPython Slideshow Extension
# https://github.com/damianavila/RISE
RUN conda install --name python2 --quiet --yes -c bioconda zeroc-ice && \
    conda install --name python2 --quiet --yes -c damianavila82 rise && \
    conda install --name python2 --quiet --yes -c pdrops pygraphviz && \
    /opt/conda/envs/python2/bin/pip install \
        graphviz \
        gseapy \
        py2cytoscape \
        pydot \
        tqdm \
        git+https://github.com/IDR/idr-py@develop

RUN mkdir -p /home/jovyan/.local/share/jupyter/kernels/python2 && \
    sed 's/Python 2/OMERO Python 2/' \
        /opt/conda/envs/python2/share/jupyter/kernels/python2/kernel.json > \
        /home/jovyan/.local/share/jupyter/kernels/python2/kernel.json

# Don't rename user- causes problems with earlier hardcoded paths
#RUN usermod -l omero jovyan -m -d /home/omero
#USER omero

# This will be updated and made read-only during startup
RUN git clone https://github.com/IDR/idr-notebooks.git /notebooks
ADD update-notebooks-and-start.sh /usr/local/bin/update-notebooks-and-start.sh

CMD ["update-notebooks-and-start.sh"]
