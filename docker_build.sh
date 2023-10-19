#!/bin/bash
DOCKER=docker
${DOCKER} build -f ../Dockerfile . || err "Error during build of Dockerfile"