#!/usr/bin/env bash

#
# This script requires INSTALL_PATH (typically /opt/viral-ngs),
# and CONDA_DEFAULT_ENV (typically /opt/miniconda) to be set.
#
# A micromamba install must exist at $CONDA_DEFAULT_ENV
# and $CONDA_DEFAULT_ENV/bin must be in the PATH

set -e -o pipefail -x

DEBUG=0 # set DEBUG=1 for more verbose output
CONDA_INSTALL_TIMEOUT="90m"
LANG=C

export G_SLICE=always-malloc
export MAMBA_ALWAYS_YES=true

if [[ $DEBUG == 1 ]]; then 
    # If DEBUG=1, set MAMBA_DEBUG_LEVEL
    # '-v':    detailed output
    # '-vv':   INFO logging
    # '-vvv':  DEBUG logging
    # '-vvvv': four times for TRACE logging.
    # See:
    #   https://docs.conda.io/projects/conda/en/stable/commands/install.html#conda.cli.conda_argparse-generate_parser-output,-prompt,-and-flow-control-options
    MAMBA_DEBUG_LEVEL="-vv"
fi

echo "PATH:                       ${PATH}"
echo "INSTALL_PATH:               ${INSTALL_PATH}"
echo "CONDA_PREFIX:               ${CONDA_PREFIX}"
echo "MAMBA_ROOT_PREFIX:          ${MAMBA_ROOT_PREFIX}"
echo "MINICONDA_PATH:             ${MINICONDA_PATH}"
echo "CONDA_DEFAULT_ENV:          ${CONDA_DEFAULT_ENV}"
echo "CONDA_PACKAGE_INSTALL_OPTS: ${CONDA_PACKAGE_INSTALL_OPTS}"
echo "CONDA_CHANNEL_STRING:       ${CONDA_CHANNEL_STRING}"
echo "PYTHON_VERSION:             ${PYTHON_VERSION}"

echo "Conda version:  $(conda --version)"
echo "Mamba version:  $(mamba --version)"
echo "Python version: $(python --version)"
echo "which python:   $(which python)"
echo "which conda:    $(which conda)"
echo "which mamba:    $(which mamba)"
echo "conda list:     $(conda list)"
echo "conda config --show:"
echo "$(conda config --show)"

#conda config --set experimental_sat_error_message true
#conda config --set use_lockfiles False

# solving the dependency graph for a conda environment can take a while.
# so long, in fact, that the conda process can run for >10 minutes without
# writing to stderr/stdout. That means Travis CI is likely to kill the job
# these functions write out periodically to keep the build job alive
#   adapted from:
#     https://github.com/matthew-brett/multibuild/blob/d1252d15e95712700865fe4a3e7c20f978efba03/common_utils.sh
# similar to travis_wait, but with output
#   see: 
#     https://docs.travis-ci.com/user/common-build-problems/#build-times-out-because-no-output-was-received

# Work round bug in travis xcode image described at
# https://github.com/direnv/direnv/issues/210
shell_session_update() { :; }
unset -f cd
unset -f pushd
unset -f popd

function start_keepalive {
    if [ -n "$KEEPALIVE_PID" ]; then
        return
    fi

    >&2 echo "Running..."
    # Start a process that runs as a keep-alive
    # to avoid having the CI running quit if there is no output
    # also keep track of start time and report human-readable duration as part of the heartbeat log lines
    (local start_time=$(date +%s)
        while true; do
        sleep 120;
        local current_time=$(date +%s);
        local elapsed_time=$((current_time - start_time));
        local elapsed_time_human=$(date -u -d @$elapsed_time +%Hh:%Mm:%Ss);
        >&2 echo "Still running (${elapsed_time_human})..."
    done) &
    KEEPALIVE_PID=$!
    disown
}

function stop_keepalive {
    if [ ! -n "$KEEPALIVE_PID" ]; then
        return
    fi

    kill $KEEPALIVE_PID
    unset KEEPALIVE_PID

    >&2 echo "Done."
}
trap stop_keepalive EXIT SIGINT SIGQUIT SIGTERM

# setup/install viral-ngs directory tree and conda dependencies
sync

REQUIREMENT_FILE_PATHS_STR=""
for condafile in $*; do
    REQUIREMENT_FILE_PATHS_STR="$REQUIREMENT_FILE_PATHS_STR --file $condafile"

    # print dependency tree for all packages in file
    [[ $DEBUG == 1 ]] && grep -vE '^#' "${condafile}" | xargs -I {} mamba repoquery depends $CONDA_CHANNEL_STRING --quiet --pretty --recursive --tree "{}";
done


ENV_NAME="base"
if ! micromamba env list | cut -w -f2 | grep -E '(^\s*'${ENV_NAME}'$)'; then
    micromamba create -n $ENV_NAME
fi

# run conda install with keepalive subshell process running in background
# to keep travis build going. Enforce a hard timeout via timeout GNU coreutil
start_keepalive
#mamba create -y -q $MAMBA_DEBUG_LEVEL $CONDA_PACKAGE_INSTALL_OPTS $CONDA_CHANNEL_STRING --prefix ${CONDA_PREFIX} $REQUIREMENT_FILE_PATHS_STR
#micromamba create -y -q $MAMBA_DEBUG_LEVEL $CONDA_PACKAGE_INSTALL_OPTS $CONDA_CHANNEL_STRING --prefix ${CONDA_PREFIX} $REQUIREMENT_FILE_PATHS_STR
#micromamba create -y -q $MAMBA_DEBUG_LEVEL $CONDA_PACKAGE_INSTALL_OPTS $CONDA_CHANNEL_STRING --name base $REQUIREMENT_FILE_PATHS_STR
# THIS IS MOST RECENT micromamba create -y -q $MAMBA_DEBUG_LEVEL $CONDA_PACKAGE_INSTALL_OPTS $CONDA_CHANNEL_STRING python=${PYTHON_VERSION} $REQUIREMENT_FILE_PATHS_STR
micromamba install $CONDA_PACKAGE_INSTALL_OPTS $CONDA_CHANNEL_STRING --quiet --yes python=${PYTHON_VERSION} --file $REQUIREMENTS_FILE
stop_keepalive

#source "${MINICONDA_PATH}/etc/profile.d/conda.sh"
#source "${MINICONDA_PATH}/etc/profile.d/mamba.sh"
#hash -r
#conda init --quiet --all --system

micromamba shell init --shell bash --root-prefix "$MAMBA_ROOT_PREFIX"
eval "$("${MAMBA_ROOT_PREFIX}/bin/micromamba" shell hook --shell bash --root-prefix "$MAMBA_ROOT_PREFIX")"
micromamba activate

hash -r

#source ${MINICONDA_PATH}/bin/activate ${CONDA_PREFIX}

mamba list

# clean up
#conda clean -y --all
micromamba clean -y --all
