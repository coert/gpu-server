#!/bin/bash

# 2023-10 halloween edition
# coert.vangemeren@hu.nl

if [[ "${DEBUG}" -eq "1" ]]; then
  set -x
fi
# turn on bash's job control
set -m

WORKDIR=/usr/src/app

BIN_PATH=/usr/bin
BIN_LOCAL_PATH=/usr/local/bin

PYTHON3=${BIN_PATH}/python3
GPUSTAT=${BIN_LOCAL_PATH}/gpustat

function err() {
  echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')]: $@" >&2
  exit 1
}

if [[ "${WITH_GPU}" -eq "1" ]]; then
  ${GPUSTAT} &> /dev/null || err "gpustat could not find any GPUs!"
fi

sleep infinity & wait