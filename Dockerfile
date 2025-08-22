
# ========================== Dockerfile global scope ===========================
#
# any of the following arguments can be overridden at the time of 'docker build' by passing new values
#   ex.:
#     --build-args ARG_TO_OVERRIDE="$OVERRIDE_VALUE"
# Note that these arguments are declared here before the first FROM statement
# so these arguments and their values can be used within the scope of distinct build stages below
#

# Python version to install in the conda (micromamba) environment
ARG PYTHON_VERSION=3.12

# Conda settings and path prefixes
ARG CONDA_PACKAGE_INSTALL_OPTS="--strict-channel-priority"
ARG CONDA_CHANNEL_STRING="--override-channels -c conda-forge -c broad-viral -c bioconda"
ARG MICROMAMBA_CONTAINING_PATH="/opt/micromamba"
ARG MAMBA_ROOT_PREFIX="$MICROMAMBA_CONTAINING_PATH"
ARG CONDA_PREFIX="$MICROMAMBA_CONTAINING_PATH"

# Miniwdl settings
ARG MINIWDL__SCHEDULER__CONTAINER_BACKEND=udocker

ARG GOOGLE_CLOUD_CLI_PATH="/opt/google-cloud-sdk"

# Executable path settings (system PATH and python path for Google Cloud SDK)
ARG PATH="${MICROMAMBA_CONTAINING_PATH}/bin:${MICROMAMBA_CONTAINING_PATH}/envs/base/bin:${GOOGLE_CLOUD_CLI_PATH}/bin:/opt/dx-toolkit/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
ARG CLOUDSDK_PYTHON=${MICROMAMBA_CONTAINING_PATH}/envs/base/bin/python3

# Path of helper files (from alongside this Dockerfile) when copied to within container
ARG BASEIMAGE_SETUP_SCRIPT_PATH_IN_CONTAINER=/opt/docker

# Locale/sharacter encoding and timezone settings
ARG LANG="en_US.UTF-8"
ARG LANGUAGE="en_US:en"
ARG LC_ALL="en_US.UTF-8"
ARG TZ="UTC"

# other settings
ARG BENCHMARK_MIRRORS=true
ARG REMOVE_APT_FAST_AFTER_BUILD=true
# ==============================================================================


# ============================== Install stage =================================
FROM ubuntu:noble-20250415.1 AS build
LABEL maintainer="viral-ngs team <viral-ngs@broadinstitute.org>"

# specify arguments in this build stage ('build') to inherit values from the Dockerfile global scope
ARG PYTHON_VERSION \
    MICROMAMBA_CONTAINING_PATH \
    MAMBA_ROOT_PREFIX \
    CONDA_PREFIX \
    CONDA_PACKAGE_INSTALL_OPTS \
    CONDA_CHANNEL_STRING \
    PATH \
    MINIWDL__SCHEDULER__CONTAINER_BACKEND \
    GOOGLE_CLOUD_CLI_PATH \
    CLOUDSDK_PYTHON \
    BASEIMAGE_SETUP_SCRIPT_PATH_IN_CONTAINER \
    LANG \
    LANGUAGE \
    LC_ALL \
    TZ \
    BENCHMARK_MIRRORS \
    REMOVE_APT_FAST_AFTER_BUILD

ENV LANG="${LANG}" \
    LANGUAGE="${LANGUAGE}" \
    LC_ALL="${LC_ALL}" \
    TZ="${TZ}" \
    CONDA_PACKAGE_INSTALL_OPTS="${CONDA_PACKAGE_INSTALL_OPTS}" \
    CONDA_CHANNEL_STRING="${CONDA_CHANNEL_STRING}" \
    MICROMAMBA_CONTAINING_PATH="${MICROMAMBA_CONTAINING_PATH}" \
    PYTHON_VERSION="${PYTHON_VERSION}" \
    MAMBA_ROOT_PREFIX="${MAMBA_ROOT_PREFIX}" \
    CONDA_PREFIX="${CONDA_PREFIX}" \
    BENCHMARK_MIRRORS="${BENCHMARK_MIRRORS}" \
    REMOVE_APT_FAST_AFTER_BUILD="${REMOVE_APT_FAST_AFTER_BUILD}" \
    GOOGLE_CLOUD_CLI_PATH="${GOOGLE_CLOUD_CLI_PATH}" \
    CLOUDSDK_PYTHON="${CLOUDSDK_PYTHON}" \
    PATH="${PATH}"

COPY install-*.sh \
    postinstall-*.sh \
    requirements-*.txt \
    ${BASEIMAGE_SETUP_SCRIPT_PATH_IN_CONTAINER}/

#WORKDIR /opt

# System packages, Google Cloud CLI, and locale
# ca-certificates and wget needed for gosu
# bzip2, liblz4-toolk, and pigz are useful for packaging and archival
# google-cloud-cli needed when using this in GCE
RUN ${BASEIMAGE_SETUP_SCRIPT_PATH_IN_CONTAINER}/install-apt_packages.sh ${BASEIMAGE_SETUP_SCRIPT_PATH_IN_CONTAINER}/requirements-system-packages.txt && \
    ${BASEIMAGE_SETUP_SCRIPT_PATH_IN_CONTAINER}/install-apt_external_repo_keys.sh && \
    ${BASEIMAGE_SETUP_SCRIPT_PATH_IN_CONTAINER}/postinstall-cleanup_apt_packages.sh ${BASEIMAGE_SETUP_SCRIPT_PATH_IN_CONTAINER}/requirements-system-packages-to-remove-after-build.txt
    # ${BASEIMAGE_SETUP_SCRIPT_PATH_IN_CONTAINER}/install-apt_packages.sh ${BASEIMAGE_SETUP_SCRIPT_PATH_IN_CONTAINER}/requirements-system-packages-from-nonstandard-sources.txt && \

RUN echo "LC_ALL=en_US.UTF-8" >> /etc/environment && \
    echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen && \
    echo "LANG=en_US.UTF-8" > /etc/locale.conf && \
    locale-gen en_US.UTF-8

# install miniconda3 with our default channels and no other packages
#ENV MINICONDA_PATH="/opt/miniconda"
#RUN ${BASEIMAGE_SETUP_SCRIPT_PATH_IN_CONTAINER}/install-miniforge-conda.sh ${BASEIMAGE_SETUP_SCRIPT_PATH_IN_CONTAINER}/requirements-conda-base-env.txt
#RUN ${BASEIMAGE_SETUP_SCRIPT_PATH_IN_CONTAINER}/install-micromamba.sh ${BASEIMAGE_SETUP_SCRIPT_PATH_IN_CONTAINER}/requirements-conda-base-env.txt
RUN ${BASEIMAGE_SETUP_SCRIPT_PATH_IN_CONTAINER}/install-micromamba.sh
RUN ${BASEIMAGE_SETUP_SCRIPT_PATH_IN_CONTAINER}/install-conda-packages.sh ${BASEIMAGE_SETUP_SCRIPT_PATH_IN_CONTAINER}/requirements-conda-base-env.txt

RUN ${BASEIMAGE_SETUP_SCRIPT_PATH_IN_CONTAINER}/install-google-cloud-sdk.sh

# install udocker
RUN ${BASEIMAGE_SETUP_SCRIPT_PATH_IN_CONTAINER}/install-udocker.sh

# install DNAnexus SDK and UA
RUN ${BASEIMAGE_SETUP_SCRIPT_PATH_IN_CONTAINER}/install-dnanexus-cli.sh

# install miniwdl
#RUN pip3 install miniwdl==1.11.1

# install qsv (binary for manipulation and query of tabular data files like tsv)
RUN ${BASEIMAGE_SETUP_SCRIPT_PATH_IN_CONTAINER}/install-qsv.sh

# remove helper scripts from image
RUN rm -rf /opt/docker
# ==============================================================================


# ========================= Image consolidation stage ==========================
#
# second stage build to "squash" layers from prior build
#
# NB: the docker ARGs and image environment 
#     variables must be set again for each build stage
#
# basing this build stage on the same base image rather than the empty 
# 'scratch' base image (as in "FROM scratch") is beneficial for image overlay 
# systems that can diff and avoid copying identical files during the 
# copy-from-previous-build operation (i.e. containerd, possibly others)

FROM ubuntu:noble-20250415.1
# FROM scratch

# specify arguments in this build stage ('build') to inherit values from the Dockerfile global scope
ARG PYTHON_VERSION \
    MICROMAMBA_CONTAINING_PATH \
    MAMBA_ROOT_PREFIX \
    CONDA_PREFIX \
    PATH \
    MINIWDL__SCHEDULER__CONTAINER_BACKEND \
    CLOUDSDK_PYTHON \
    BASEIMAGE_SETUP_SCRIPT_PATH_IN_CONTAINER \
    LANG \
    LANGUAGE \
    LC_ALL \
    TZ

ENV LANG="${LANG}" \
    LANGUAGE="${LANGUAGE}" \
    LC_ALL="${LC_ALL}" \
    TZ="${TZ}" \
    MICROMAMBA_CONTAINING_PATH="${MICROMAMBA_CONTAINING_PATH}" \
    PYTHON_VERSION="${PYTHON_VERSION}" \
    MAMBA_ROOT_PREFIX="${MAMBA_ROOT_PREFIX}" \
    CONDA_PREFIX="${CONDA_PREFIX}" \
    PATH="${PATH}" \
    MINIWDL__SCHEDULER__CONTAINER_BACKEND="${MINIWDL__SCHEDULER__CONTAINER_BACKEND}" \
    PATH="${PATH}" \
    GOOGLE_CLOUD_CLI_PATH="${GOOGLE_CLOUD_CLI_PATH}" \
    CLOUDSDK_PYTHON="${CLOUDSDK_PYTHON}"

# clear CLOUDSDK_PYTHON_SITEPACKAGES
# see:
#   https://cloud.google.com/sdk/crypto#cloudsdk_python_sitepackages=1
#ENV CLOUDSDK_PYTHON_SITEPACKAGES=

    # CONDA_PACKAGE_INSTALL_OPTS="${CONDA_PACKAGE_INSTALL_OPTS}" \
    #CONDA_CHANNEL_STRING="${CONDA_CHANNEL_STRING}" \

# Copy files from the install stage;
# most modern image build systems should
# de-duplicate files relative to the ubuntu base image
# resulting in a smaller squashed image containing the delta
# from the baseimage
COPY --from=build / /

# set up entrypoint
CMD ["/bin/bash"]

