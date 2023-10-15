#!/usr/bin/bash

IMAGE_NAME="sdfstudio:cuda-only-11.8.0-devel-ubuntu22.04"
# IMAGE_NAME="dromni/nerfstudio:0.3.4"
WS_PORT=7007
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
WORK_DIR="/workspace"
SAVE_DIR="/home/$USER/mr-proj/workspace"

docker run -it --rm --ipc=host --gpus all \
  -p ${WS_PORT}:7007 \
  -v /datasets/$USER:/dataset \
  -v ${SAVE_DIR}:${WORK_DIR} \
  ${IMAGE_NAME}