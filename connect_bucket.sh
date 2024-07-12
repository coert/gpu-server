#!/bin/bash
WHOAMI=$(whoami)

WORKSPACE=/home/${WHOAMI}/workspace
LOCAL_BUCKET=/home/${WHOAMI}/bucket
mkdir -p ${LOCAL_BUCKET}
cd ${WORKSPACE}
ln -sf ${LOCAL_BUCKET} ${WORKSPACE}/bucket

BIN_PATH=/usr/bin
BIN_LOCAL_PATH=/usr/local/bin
GCSFUSE=${BIN_PATH}/gcsfuse

PROJECT_STAGE=dev
PROJECT_ID=spyne-275620

GCP_BUCKET=${PROJECT_ID}_assets_${PROJECT_STAGE}

${GCSFUSE} --implicit-dirs -o nonempty ${GCP_BUCKET} ${LOCAL_BUCKET}
