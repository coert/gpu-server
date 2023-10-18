#!/bin/bash
DOCKER=docker
${DOCKER} build -f Dockerfile.dev . || err "Error during build of Dockerfile"