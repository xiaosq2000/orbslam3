#!/bin/bash

COMPILE_JOBS=12
HTTP_PROXY=${HTTP_PROXY}
HTTPS_PROXY=${HTTPS_PROXY}

# WSL2
docker build . -t orbslam3_dev \
--build-arg COMPILE_JOBS=${COMPILE_JOBS} \
--build-arg HTTP_PROXY=${HTTP_PROXY} \
--build-arg HTTPS_PROXY=${HTTPS_PROXY}
