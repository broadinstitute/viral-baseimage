#!/bin/bash
set -e -o pipefail

# for current versions of miniforge, see:
#   https://github.com/conda-forge/miniforge/releases

# give MINICONDA_PATH a default value of /opt/miniconda if MINICONDA_PATH is not set as an environment variable
MINICONDA_PATH=${MINICONDA_PATH:-"/opt/miniconda"}

MINIFORGE_VERSION="24.11.3-2"
MINIFORGE_URL="https://github.com/conda-forge/miniforge/releases/download/${MINIFORGE_VERSION}/Miniforge3-${MINIFORGE_VERSION}-Linux-$(uname -m).sh"
curl -sSL $MINIFORGE_URL > "/tmp/Miniforge3-${MINIFORGE_VERSION}-$(uname -m).sh"
chmod a+x "/tmp/Miniforge3-${MINIFORGE_VERSION}-$(uname -m).sh"
/tmp/Miniforge3-${MINIFORGE_VERSION}-$(uname -m).sh -b -f -p "$MINICONDA_PATH"
rm "/tmp/Miniforge3-${MINIFORGE_VERSION}-$(uname -m).sh"

PATH="$MINICONDA_PATH/bin:$PATH"
hash -r
conda config --set always_yes yes --set changeps1 no
conda config --append  channels bioconda
conda config --prepend channels broad-viral
conda config --set auto_update_conda false
conda clean -y --all

source "${MINICONDA_PATH}/etc/profile.d/conda.sh"
source "${MINICONDA_PATH}/etc/profile.d/mamba.sh"
hash -r
conda init

conda activate

mamba --version