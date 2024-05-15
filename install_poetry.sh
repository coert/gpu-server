#!/bin/bash
curl -sSL https://install.python-poetry.org | python3 -
poetry install --with tensorflow --with torch --with google --with dev

curl -LsSf https://astral.sh/uv/install.sh | sh
uv venv
uv pip compile pyproject.toml --python-version 3.12 --all-extras -o requirements.txt
uv pip install -r requirements.txt