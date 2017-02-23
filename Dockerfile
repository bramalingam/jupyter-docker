FROM jupyter/datascience-notebook:latest

MAINTAINER ome-devel@lists.openmicroscopy.org.uk

################################################################################
# Custom
################################################################################

USER root

## Swap the name of NB_USER
RUN usermod -l omero $NB_USER && \
    ln -s /home/$NB_USER /home/omero && \
    mkdir -p /home/omero/data && \
    chown omero /home/omero/data && \
    chmod a+X /home/omero
ENV NB_USER omero
# Note: this replaces "OMERO_DATA_DIR=/home/omero/data bash -eux step02_all_setup.sh"

## Do omero-install
ENV PATH=$CONDA_DIR/envs/python2/bin/:$PATH
RUN mkdir /omero-install
WORKDIR /omero-install
RUN git clone git://github.com/ome/omero-install .
WORKDIR /omero-install/linux
ENV ICEVER=ice36
RUN \
	bash -eux step01_ubuntu1404_init.sh && \
	bash -eux step01_debian8_java_deps.sh && \
	bash -eux step01_debian8_deps.sh && \
	bash -eux step01_debian8_ice_deps.sh

## Add other dependencies
USER omero
ENV PATH=$CONDA_DIR/envs/python2/bin/:$PATH
WORKDIR /home/omero
RUN pip install omego && \
    omego install --ice 3.6 --no-start && \
    pip install markdown sklearn joblib && \
    conda install -c bioconda python-igraph=0.7.1.post6 && \
    echo 'export PYTHONPATH=$HOME/OMERO-CURRENT/lib/python' >> $HOME/.bashrc

## Revert PATH
ENV PATH=/opt/conda/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
RUN echo /home/omero/OMERO-CURRENT/lib/python/ > /opt/conda/envs/python2/lib/python2.7/site-packages/omero.pth


## RISE
RUN git clone https://github.com/damianavila/RISE /tmp/RISE && \
    cd /tmp/RISE && $CONDA_DIR/envs/python2/bin/python setup.py install

## Add a notebook profile.
USER root
RUN mkdir /notebooks
RUN chown -R omero /notebooks
USER omero
WORKDIR /notebooks
RUN mkdir -p -m 700 $HOME/.jupyter/ && \
    echo "c.NotebookApp.ip = '*'" >> $HOME/.jupyter/jupyter_notebook_config.py

# RUN mkdir -p /home/omero/.local/share/jupyter/kernels/python2/
# COPY kernel.json /home/omero/.local/share/jupyter/kernels/python2/kernel.json

#CMD ["env", "PYTHONPATH=/home/omero/OMERO-CURRENT/lib/python", "python", "/usr/local/bin/jupyter", "notebook", "--no-browser", "--ip=0.0.0.0"]
#EXPOSE 8888
