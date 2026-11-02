# Python image used by tools/*.py: docker build -t kossel-cad-tools tools/
FROM python:3.12-slim
RUN apt-get update && apt-get install -y --no-install-recommends libgl1 libglu1-mesa libxrender1 libxext6 && rm -rf /var/lib/apt/lists/*
RUN pip install --no-cache-dir numpy trimesh matplotlib cadquery shapely rtree scipy manifold3d networkx
WORKDIR /work
