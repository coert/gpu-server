#!/bin/bash
WORKSPACE=/opt/workspace

cd ~
mkdir -p data/workspace
ln -s ~/data/workspace workspace
cd workspace

# Copy the pyproject.toml file to the root directory
cp $WORKSPACE/pyproject.toml pyproject.toml

if [[ $1 == "poetry" ]]; then
    curl -sSL https://install.python-poetry.org | python3 -
    poetry env use python3.12
    poetry lock
    poetry install --with tensorflow --with torch --with google --with dev

elif [[ $1 == "uv" ]]; then
    curl -LsSf https://astral.sh/uv/install.sh | sh
    uv venv
    uv pip compile pyproject.toml --python-version 3.12 --all-extras -o requirements.txt
    uv pip install -r requirements.txt
else
    echo "Invalid argument. Please use 'poetry' or 'uv'."

fi

echo "Virtual environment created successfully in '~/workspace'."
cd -