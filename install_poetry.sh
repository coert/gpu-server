#!/bin/bash
curl -sSL https://install.python-poetry.org | python3 -
poetry install --with torch --with google --with dev