# Create ./notebooks with chmod o+wt
exec docker run --name notebook_latest -d -p 8888:8888 -v /usr/local/MATLAB/R2017a:/usr/local/MATLAB/from-host --mac-address=00:00:00:00:00:00 -v "/home/parallels/Desktop/jupyter-docker/data:/notebooks" notebook_latest
#exec docker exec notebook_latest /InstallMatlabPythonEngine.sh
