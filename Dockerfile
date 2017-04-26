FROM jupyter/datascience-notebook

USER root
# Get wget
RUN apt-get update && apt-get install wget

RUN usermod -l omero $NB_USER && \
    ln -s /home/$NB_USER /home/omero && \
    mkdir -p /home/omero/data && \
    chown omero /home/omero/data && \
    chmod a+X /home/omero

ENV NB_USER omero

RUN mkdir /omero-install
WORKDIR /omero-install
RUN git clone git://github.com/ome/omero-install .
WORKDIR /omero-install/linux

RUN \
    bash -eux step01_ubuntu_init.sh && \
    bash -eux step01_debian8_java_deps.sh && \
    bash -eux step01_debian8_deps.sh && \
    ICEVER=ice36 bash -eux step01_debian8_ice_deps.sh && \
    OMERO_DATA_DIR=/home/omero/data bash -eux step02_all_setup.sh

# Required for matplotlib
# RUN apt-get install -y libpng-dev libjpeg62-turbo-dev libfreetype6-dev

RUN virtualenv --system-site-packages /home/omero/omeroenv && /home/omero/omeroenv/bin/pip install omego==0.5.0
RUN /home/omero/omeroenv/bin/omego download server --release 5.3.0 --ice 3.6  --sym auto
RUN /home/omero/omeroenv/bin/pip install markdown
#RUN /home/omero/omeroenv/bin/pip install -U matplotlib 
RUN rm -f /root/omero-install/linux/OMERO.server-5.3.0-ice36-b59.zip
RUN /home/omero/omeroenv/bin/pip install pandas sklearn joblib

USER root
#romero dependency git
RUN apt-get install -y git

# romero dependencies mvn
ARG MAVEN_VERSION=3.5.0
ARG USER_HOME_DIR="/root"
ARG SHA=beb91419245395bd69a4a6edad5ca3ec1a8b64e41457672dc687c173a495f034
ARG BASE_URL=https://apache.osuosl.org/maven/maven-3/${MAVEN_VERSION}/binaries

RUN mkdir -p /usr/share/maven /usr/share/maven/ref \
  && curl -fsSL -o /tmp/apache-maven.tar.gz ${BASE_URL}/apache-maven-$MAVEN_VERSION-bin.tar.gz \
  && echo "${SHA}  /tmp/apache-maven.tar.gz" | sha256sum -c - \
  && tar -xzf /tmp/apache-maven.tar.gz -C /usr/share/maven --strip-components=1 \
  && rm -f /tmp/apache-maven.tar.gz \
  && ln -s /usr/share/maven/bin/mvn /usr/bin/mvn

ENV MAVEN_HOME /usr/share/maven
ENV MAVEN_CONFIG "$USER_HOME_DIR/.m2"
# Matlab dependencies
#RUN apt-get install -y \
    #libpng12-dev libfreetype6-dev \
    #libblas-dev liblapack-dev gfortran build-essential xorg python-dev pkg-config

# Add matlab kernel
#RUN ln -s -f /usr/local/MATLAB/from-host/sys/os/glnxa64/libstdc++.so.6 /opt/conda/lib
#RUN /bin/bash -c "source /opt/conda/bin/activate"
#RUN /opt/conda/bin/pip install numpy
#RUN /opt/conda/bin/pip install pymatbridge
#RUN /opt/conda/bin/pip install matlab_kernel
#RUN /opt/conda/bin/python -m matlab_kernel install
#RUN /bin/bash -c "source /opt/conda/bin/deactivate"

# OR USE THE FOLLOWING LOGIC
#ENV PATH="/usr/local/MATLAB/from-host/bin:${PATH}"

# wrapper to start mounted-in matlab, plus MATLABPATH=/usr/local/MATLAB/
#ADD matlab /usr/local/bin/matlab

RUN /opt/conda/bin/conda install -c bioconda python-igraph=0.7.1.post6
#RUN /home/omero/omeroenv/bin/pip install py2cytoscape/

RUN echo 'export PYTHONPATH=$HOME/OMERO.server/lib/python' >> $HOME/.bashrc

# RISE
RUN git clone https://github.com/damianavila/RISE /tmp/RISE && \
    cd /tmp/RISE && /home/omero/omeroenv/bin/python setup.py install

# Add a notebook profile.
USER root
RUN mkdir /notebooks
RUN chown -R omero /notebooks
USER omero

WORKDIR /notebooks
RUN mkdir -p -m 700 $HOME/.jupyter/ && \
    echo "c.NotebookApp.ip = '*'" >> $HOME/.jupyter/jupyter_notebook_config.py

RUN mkdir -p /home/omero/.local/share/jupyter/kernels/python2/
COPY kernel.json /home/omero/.local/share/jupyter/kernels/python2/kernel.json



RUN echo 'export PATH= /opt/conda/bin:$PATH' >> $HOME/.bashrc
RUN echo /home/omero/OMERO-CURRENT/lib/python/ > /opt/conda/envs/python2/lib/python2.7/site-packages/omero.pth

#CMD ["env", "PYTHONPATH=/home/omero/OMERO.server/lib/python", "/home/omero/omeroenv/bin/python", "/opt/conda/bin/jupyter", "notebook", "--no-browser", "--ip=0.0.0.0"]

#RUN mkdir /notebooks/tempScriptDirectory
#ADD InstallMatlabPythonEngine.sh /notebooks/tempScriptDirectory
#CMD ["/bin/sh","-c", "/notebooks/tempScriptDirectory/InstallMatlabPythonEngine.sh"]