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
RUN mkdir /omero-install
WORKDIR /omero-install
RUN git clone git://github.com/ome/omero-install .
WORKDIR /omero-install/linux
RUN \
	bash -eux step01_ubuntu1404_init.sh && \
	bash -eux step01_debian8_java_deps.sh && \
	bash -eux step01_debian8_deps.sh && \
	bash -eux step01_debian8_ice_deps.sh

## Add other dependencies
USER omero
WORKDIR /home/omero
RUN virtualenv --system-site-packages /home/omero/omeroenv && /home/omero/omeroenv/bin/pip install omego
RUN /home/omero/omeroenv/bin/omego install --ice 3.5 --no-start
RUN /home/omero/omeroenv/bin/pip install markdown sklearn joblib
RUN conda install -c bioconda python-igraph=0.7.1.post6
RUN echo 'export PYTHONPATH=$HOME/OMERO-CURRENT/lib/python' >> $HOME/.bashrc

## RISE
RUN git clone https://github.com/damianavila/RISE /tmp/RISE && \
    cd /tmp/RISE && /home/omero/omeroenv/bin/python setup.py install

## Add a notebook profile.
USER root
RUN mkdir /notebooks
RUN chown -R omero /notebooks
USER omero
WORKDIR /notebooks
RUN mkdir -p -m 700 $HOME/.jupyter/ && \
    echo "c.NotebookApp.ip = '*'" >> $HOME/.jupyter/jupyter_notebook_config.py

RUN mkdir -p /home/omero/.local/share/jupyter/kernels/python2/
COPY kernel.json /home/omero/.local/share/jupyter/kernels/python2/kernel.json

CMD ["env", "PYTHONPATH=/home/omero/OMERO-CURRENT/lib/python", "/home/omero/omeroenv/bin/python", "/usr/local/bin/jupyter", "notebook", "--no-browser", "--ip=0.0.0.0"]
EXPOSE 8888
