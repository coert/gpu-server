#!/bin/bash
POETRY=poetry
RFILE="requirements.txt"
PFILE="poetry.lock"
${POETRY} export -f ${RFILE} --output ${RFILE} --with torch --with google --without dev || err "Unable to export ${RFILE}"
