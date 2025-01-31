#!/bin/bash
set -e -o pipefail

# download, extract, and install micromamba
#   for documentation, see:
#     https://mamba.readthedocs.io/en/latest/installation/micromamba-installation.html

MICROMAMBA_VERSION="2.0.5-0"
MICROMAMBA_URL="https://github.com/mamba-org/micromamba-releases/releases/download/${MICROMAMBA_VERSION}/micromamba-linux-64.tar.bz2"

# =========================

MICROMAMBA_CONTAINING_PATH="${MICROMAMBA_CONTAINING_PATH:-/opt/micromamba}"
MICROMAMBA_EXTRACTION_TEMP_PATH="${MICROMAMBA_EXTRACTION_TEMP_PATH:-/tmp/micromamba-${MICROMAMBA_VERSION}/bin}"

# download and install micromamba binary
mkdir -p  "${MICROMAMBA_EXTRACTION_TEMP_PATH}"
curl -Ls   ${MICROMAMBA_URL} | tar --extract --bzip2 --to-stdout bin/micromamba > "${MICROMAMBA_EXTRACTION_TEMP_PATH}/micromamba"
chmod a+x "${MICROMAMBA_EXTRACTION_TEMP_PATH}/micromamba"

mkdir -p  "${MICROMAMBA_CONTAINING_PATH}/bin"
mv        "${MICROMAMBA_EXTRACTION_TEMP_PATH}/micromamba" "$MICROMAMBA_CONTAINING_PATH/bin/micromamba"
rm -rf "${MICROMAMBA_EXTRACTION_TEMP_PATH}"

export PATH="$MICROMAMBA_CONTAINING_PATH/bin:$PATH"
hash -r

# Named environments live in $MAMBA_ROOT_PREFIX/envs/
export MAMBA_ROOT_PREFIX="${MICROMAMBA_CONTAINING_PATH}"
echo "MAMBA_ROOT_PREFIX: ${MAMBA_ROOT_PREFIX}"
echo ""

micromamba shell init --shell bash --root-prefix "$MAMBA_ROOT_PREFIX"
eval "$(micromamba shell hook --shell bash --root-prefix "$MAMBA_ROOT_PREFIX")"

micromamba config set always_yes yes 
micromamba config set changeps1 no

micromamba config append channels r # perhaps can be removed as a package source
micromamba config append channels bioconda
micromamba config append channels conda-forge
micromamba config append channels broad-viral
#micromamba config set channel_priority strict

# create symlinks to micromamba from "mamba" and "conda"
# this will allow most commands to make use of micromamba 
# transparently, though there are some differences in API (ex. "conda config --add" vs "micromamba config append")
ln -s $MICROMAMBA_CONTAINING_PATH/bin/micromamba $MICROMAMBA_CONTAINING_PATH/bin/mamba
ln -s $MICROMAMBA_CONTAINING_PATH/bin/micromamba $MICROMAMBA_CONTAINING_PATH/bin/conda

micromamba activate  # this activates the base environment
micromamba install python=${PYTHON_VERSION} --file /opt/docker/requirements-conda.txt
hash -r

micromamba clean -y --all

echo "content of $MICROMAMBA_CONTAINING_PATH/bin:"
ls -lah $MICROMAMBA_CONTAINING_PATH/bin