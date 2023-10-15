#!/usr/bin/bash

IMAGE_NAME="sdfstudio:cuda-only-11.8.0-devel-ubuntu22.04"
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
WORK_DIR="/workspace"
SAVE_DIR="/home/$USER/mr-proj/workspace"

if ! [[ "$(docker image ls -q ${IMAGE_NAME} 2> /dev/null)" == "" ]]; then
  docker image rm ${IMAGE_NAME}
fi
docker build -t ${IMAGE_NAME} --build-arg username="$USER" --build-arg uid=$(id -u) --build-arg gid=$(id -g) ${SCRIPT_DIR}