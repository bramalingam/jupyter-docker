FROM jupyter/notebook:latest

# Matlab dependencies
RUN apt-get update && apt-get install -y \
    libpng12-dev libfreetype6-dev \
    libblas-dev liblapack-dev gfortran build-essential xorg

# run the container like a matlab executable 
# ENV PATH="/usr/local/MATLAB/from-host/bin:${PATH}"
ENV PATH="/Applications/MATLAB_R2017a.app/bin:${PATH}"
ENTRYPOINT ["matlab", "-logfile /var/log/matlab/matlab.log"]

# Get wget
RUN apt-get install wget

# Install 
RUN echo 'export PATH=/opt/conda/bin:$PATH' > /etc/profile.d/conda.sh && \
    wget --quiet https://repo.continuum.io/archive/Anaconda3-4.3.1-Linux-x86_64.sh -O ~/anaconda.sh && \
    /bin/bash ~/anaconda.sh -b -p /opt/conda && \
    rm ~/anaconda.sh

# Add matlab kernel
RUN pip install --upgrade pip
RUN pip3 install numpy
RUN pip3 install pymatbridge
RUN pip3 install matlab_kernel
RUN python3 -m matlab_kernel install

# Add a notebook profile.
WORKDIR /notebooks
RUN mkdir -p -m 700 $HOME/.jupyter/ && \
    echo "c.NotebookApp.ip = '*'" >> $HOME/.jupyter/jupyter_notebook_config.py

RUN mkdir -p /home/omero/.local/share/jupyter/kernels/python2/
COPY kernel.json /home/omero/.local/share/jupyter/kernels/python2/kernel.json

CMD ["env", "PYTHONPATH=/usr/local/bin/jupyter", "notebook", "--no-browser", "--ip=0.0.0.0"]
