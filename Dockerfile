# Define base image.
# FROM sdfstudio-base:11.8.0-devel-ubuntu22.04
FROM nvidia/cuda:11.8.0-devel-ubuntu22.04

ARG username
ARG uid
ARG gid

# Set environment variables.
## Set non-interactive to prevent asking for user inputs blocking image creation.
ENV DEBIAN_FRONTEND=noninteractive
## Set timezone as it is required by some packages.
ENV TZ=Europe/Berlin
## CUDA architectures, required by tiny-cuda-nn.
ARG MY_GPU_ARCH=86
ENV TCNN_CUDA_ARCHITECTURES=${MY_GPU_ARCH}
## CUDA Home, required to find CUDA in some packages.
ENV CUDA_HOME="/usr/local/cuda"

# Install required apt packages.
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    build-essential \
    cmake \
    ffmpeg \
    git \
    libatlas-base-dev \
    libboost-filesystem-dev \
    libboost-graph-dev \
    libboost-program-options-dev \
    libboost-system-dev \
    libboost-test-dev \
    libcgal-dev \
    libeigen3-dev \
    libfreeimage-dev \
    libgflags-dev \
    libglew-dev \
    libgoogle-glog-dev \
    libmetis-dev \
    libprotobuf-dev \
    libqt5opengl5-dev \
    libsuitesparse-dev \
    nano \
    protobuf-compiler \
    python3-dev \
    python3-pip \
    qtbase5-dev \
    wget

# Install colmap.
## use CUDA 11.8 or specify GPU uarch via CMAKE_CUDA_ARCHITECTURES
## from https://colmap.github.io/install.html
## if not specified, will build arch from 35 to 86 + PTX
## but 35 is not supported anymore after CUDA 12.0
## add: build will fail in cuda 12
RUN apt-get update && apt-get install -y \
    ninja-build \
    libflann-dev \
    libgtest-dev \
    libsqlite3-dev \
    libceres-dev

RUN git clone --branch 3.8 https://github.com/colmap/colmap.git --single-branch && \
    cd colmap && \
    mkdir build && \
    cd build && \
    cmake .. -GNinja -DCMAKE_CUDA_ARCHITECTURES=${MY_GPU_ARCH} && \
    ninja && \
    ninja install && \
    cd ../.. && rm -rf colmap
    
# Create non root user and setup environment.
## The user has exactly the same uid:gid as builder
## which allows read/write to mounted volumn
RUN groupadd -g ${gid} -o ${username}
RUN useradd -m -d /home/${username} -u ${uid} -g ${gid} -o ${username}

# Switch to new uer and workdir.
USER ${username}
WORKDIR /home/${username}

# Add local user binary folder to PATH variable.
ENV PATH="${PATH}:/home/${username}/.local/bin"
SHELL ["/bin/bash", "-c"]

# Upgrade pip and install packages.
RUN python3 -m pip install --upgrade pip setuptools pathtools promise
# Install pytorch and submodules.
RUN python3 -m pip install torch==1.12.1+cu113 torchvision==0.13.1+cu113 torchaudio==0.12.1 --extra-index-url https://download.pytorch.org/whl/cu113
# Install tynyCUDNN.
RUN python3 -m pip install git+https://github.com/NVlabs/tiny-cuda-nn.git#subdirectory=bindings/torch

# Copy nerfstudio folder and give ownership to user.
ADD . /home/${username}/nerfstudio
USER root
RUN chown -R ${uid}:${gid} /home/${username}/nerfstudio && usermod -aG sudo ${username}
USER ${username}

# Install nerfstudio dependencies.
RUN cd nerfstudio && \
    python3 -m pip install -e . && \
    cd ..

# Change working directory
WORKDIR /workspace

## Additional missing packages
USER root
RUN apt-get update && apt-get install -y \
    curl
USER ${username}


# Install nerfstudio cli auto completion and enter shell if no command was provided.
CMD ns-install-cli --mode install && /bin/bash

