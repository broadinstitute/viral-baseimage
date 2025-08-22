#!/usr/bin/env bash
set -e -o pipefail

# download, extract, and install micromamba
#   for documentation, see:
#     https://mamba.readthedocs.io/en/latest/installation/micromamba-installation.html
#     https://mamba.readthedocs.io/en/latest/user_guide/micromamba.html
#     https://mamba.readthedocs.io/en/latest/user_guide/configuration.html
#   as well as the current bioconda channel recommendations here:
#     https://bioconda.github.io/

MICROMAMBA_VERSION="2.0.5-0"
MICROMAMBA_URL="https://github.com/mamba-org/micromamba-releases/releases/download/${MICROMAMBA_VERSION}/micromamba-linux-64.tar.bz2"

# =========================

MICROMAMBA_CONTAINING_PATH="${MICROMAMBA_CONTAINING_PATH:-/opt/micromamba}"
MICROMAMBA_EXTRACTION_TEMP_PATH="${MICROMAMBA_EXTRACTION_TEMP_PATH:-/tmp/micromamba-${MICROMAMBA_VERSION}/bin}"

CONDA_CHANNEL_STRING="${CONDA_CHANNEL_STRING:-"--override-channels -c conda-forge -c broad-viral -c bioconda"}"
#CONDA_PACKAGE_INSTALL_OPTS="${CONDA_PACKAGE_INSTALL_OPTS:-"--strict-channel-priority"}"

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

echo "--------------------------------------------------------------------------------"
env
echo ""
echo "MAMBA_ROOT_PREFIX:          ${MAMBA_ROOT_PREFIX}"
echo "PATH:                       ${PATH}"
echo "INSTALL_PATH:               ${INSTALL_PATH}"
echo "CONDA_PREFIX:               ${CONDA_PREFIX}"
echo "MAMBA_ROOT_PREFIX:          ${MAMBA_ROOT_PREFIX}"
echo "MINICONDA_PATH:             ${MINICONDA_PATH}"
echo "CONDA_DEFAULT_ENV:          ${CONDA_DEFAULT_ENV}"
echo "CONDA_PACKAGE_INSTALL_OPTS: ${CONDA_PACKAGE_INSTALL_OPTS}"
echo "CONDA_CHANNEL_STRING:       ${CONDA_CHANNEL_STRING}"
echo "PYTHON_VERSION:             ${PYTHON_VERSION}"

echo "Conda version:       $(conda --version)"
echo "Mamba version:       $(mamba --version)"
echo "Micromamba version:  $(micromamba --version)"
echo "Python version:      $(python --version)"
echo "which python:        $(which python)"
echo "which conda:         $(which conda)"
echo "which mamba:         $(which mamba)"
echo "conda list:          $(conda list)"
echo "conda config --show:"
echo "$(conda config --show)"
micromamba info
micromamba config list channels
echo "--------------------------------------------------------------------------------"
echo ""

micromamba shell init --shell bash --root-prefix "$MAMBA_ROOT_PREFIX"
eval "$("${MAMBA_ROOT_PREFIX}/bin/micromamba" shell hook --shell bash --root-prefix "$MAMBA_ROOT_PREFIX")"

micromamba config set always_yes yes 
micromamba config set changeps1 no

#micromamba config append channels r # perhaps can be removed as a package source
micromamba config append channels bioconda
micromamba config append channels conda-forge
micromamba config append channels broad-viral
micromamba config remove channels defaults || echo "defaults channel not found"
#micromamba config set channel_priority strict

# create symlinks to micromamba from "mamba" and "conda"
# this will allow most commands to make use of micromamba 
# transparently, though depending on the versions of each,
# there are some differences in API (ex. "conda config --add" vs "micromamba config append")
ln -s $MICROMAMBA_CONTAINING_PATH/bin/micromamba $MICROMAMBA_CONTAINING_PATH/bin/mamba
ln -s $MICROMAMBA_CONTAINING_PATH/bin/micromamba $MICROMAMBA_CONTAINING_PATH/bin/conda

#micromamba activate  # this activates the "base" environment

#micromamba install python=${PYTHON_VERSION} --file /opt/docker/requirements-conda.txt

# check if an additional argument has been passed to this script, 
# and if it is a file that exists and which `file --brief --mime-type $INFILE_REQUIREMENTS` returns 'text/plain'
if [ -n "$1" ] && [ -f "$1" ] && [ "$(file --brief --mime-type "$1")" == "text/plain" ]; then
    REQUIREMENTS_FILE=$1
    echo "micromamba installing conda packages from $(realpath $REQUIREMENTS_FILE)"
    mapfile -t pkgs < <(grep -E -v '^(#.*)?$' "$REQUIREMENTS_FILE")
    if (( ${#pkgs[@]} )); then
        # check if environment called "base" exists. If it does not, call micromamba create [...] to create
        # it with the specified dependencies. If it does exist, call micromamba install [...] to add the
        # specified dependencies to the existing base environment.
        ENV_NAME="base"
        if ! micromamba env list | cut -w -f2 | grep -E '(^\s*'${ENV_NAME}'$)'; then
            micromamba create -n $ENV_NAME
        fi
        #micromamba install -n base --quiet --yes python=${PYTHON_VERSION} --file $REQUIREMENTS_FILE
        micromamba install $CONDA_PACKAGE_INSTALL_OPTS $CONDA_CHANNEL_STRING --quiet --yes python=${PYTHON_VERSION} --file $REQUIREMENTS_FILE
    fi
else
    echo "No valid input file provided, skipping package installation."
fi
#micromamba activate base
micromamba activate

hash -r
micromamba clean -y --all

echo "contents of $MICROMAMBA_CONTAINING_PATH/bin:"
ls -lah $MICROMAMBA_CONTAINING_PATH/bin