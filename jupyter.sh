# Create ./notebooks with chmod o+wt 
# exec docker run --name ome-jupyter -d -p 8888:8888 -v "/data/notebooks:/notebooks" ome-jupyter
sudo docker run -d --name josh-jupyter -p 8888:8888 -v $PWD/notebooks:/notebooks josh-jupyter
