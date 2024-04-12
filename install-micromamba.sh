#!/bin/bash
set -e -o pipefail

MICROMAMBA_VERSION="1.5.8"
MICROMAMBA_URL="https://micro.mamba.pm/api/micromamba/linux-64/${MICROMAMBA_VERSION}"

curl -Ls https://micro.mamba.pm/api/micromamba/linux-64/latest | tar -xvj bin/micromamba

# download and run miniconda installer script
curl -sSL $MICROMAMBA_URL > "/tmp/micromamba-${MICROMAMBA_VERSION}"
chmod a+x "/tmp/micromamba-${MICROMAMBA_VERSION}"
mkdir -p "${MICROMAMBA_PATH}"
mv /tmp/micromamba-${MICROMAMBA_VERSION} "$MICROMAMBA_PATH/micromamba"

PATH="$MICROMAMBA_PATH/bin:$PATH"
hash -r

micromamba config set always_yes yes 
micromamba config set changeps1 no
micromamba config append channels r
micromamba config append channels defaults
micromamba config append channels bioconda
micromamba config append channels conda-forge
micromamba config append channels broad-viral
micromamba config set auto_update_conda false
#conda install -y mamba -c conda-forge # compatible CLI with faster solver: https://github.com/mamba-org/mamba
micromamba clean -y --all

# create symlinks to micromamba from "mamba" and "conda"
# this will allow most commands to make use of micromamba 
# transparently, though there are some differences in API (ex. "conda config --add" vs "micromamba config append")
ln -s $MICROMAMBA_PATH/micromamba $MICROMAMBA_PATH/mamba
ln -s $MICROMAMBA_PATH/micromamba $MICROMAMBA_PATH/conda


# micromamba activate  # this activates the base environment
# micromamba install python=3.10