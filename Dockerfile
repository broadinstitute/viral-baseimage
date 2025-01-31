
# ==============================================================================
ARG LANG="en_US.UTF-8"
ARG LANGUAGE="en_US:en"
ARG LC_ALL="en_US.UTF-8"
ARG TZ="UTC"
ARG MICROMAMBA_CONTAINING_PATH="/opt/micromamba"
ARG PYTHON_VERSION=3.10
ARG MAMBA_ROOT_PREFIX="$MICROMAMBA_CONTAINING_PATH"
ARG CONDA_PREFIX="$MICROMAMBA_CONTAINING_PATH"
ARG PATH="${MICROMAMBA_CONTAINING_PATH}/bin:/google-cloud-sdk/bin:/opt/dx-toolkit/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
ARG MINIWDL__SCHEDULER__CONTAINER_BACKEND=udocker
ARG PATH="/google-cloud-sdk/bin:$PATH"
ARG CLOUDSDK_PYTHON=${MICROMAMBA_CONTAINING_PATH}/bin/python3

FROM ubuntu:noble-20241118.1 AS build
ARG LANG LANGUAGE LC_ALL TZ MICROMAMBA_CONTAINING_PATH PYTHON_VERSION MAMBA_ROOT_PREFIX CONDA_PREFIX PATH MINIWDL__SCHEDULER__CONTAINER_BACKEND PATH CLOUDSDK_PYTHON
#FROM ghcr.io/mamba-org/micromamba:2.0.5-ubuntu24.04

LABEL maintainer="viral-ngs team <viral-ngs@broadinstitute.org>"

COPY install-*.sh requirements-conda.txt /opt/docker/

# System packages and locale
# ca-certificates and wget needed for gosu
# bzip2, liblz4-toolk, and pigz are useful for packaging and archival
# google-cloud-cli needed when using this in GCE
RUN /opt/docker/install-apt_packages.sh

# Set default locale to en_US.UTF-8
ENV LANG="en_US.UTF-8" LANGUAGE="en_US:en" LC_ALL="en_US.UTF-8" TZ="UTC"

# install udocker
RUN /opt/docker/install-udocker.sh

# install qsv (binary for manipulation and query of tabular data files like tsv)
RUN /opt/docker/install-qsv.sh

# install micromamba with our default channels and no other packages
ENV MICROMAMBA_CONTAINING_PATH="/opt/micromamba"
ENV PYTHON_VERSION=3.10 MAMBA_ROOT_PREFIX="$MICROMAMBA_CONTAINING_PATH" CONDA_PREFIX="$MICROMAMBA_CONTAINING_PATH"
RUN /opt/docker/install-micromamba.sh

ENV PATH="${MICROMAMBA_CONTAINING_PATH}/bin:/google-cloud-sdk/bin:/opt/dx-toolkit/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
ENV MINIWDL__SCHEDULER__CONTAINER_BACKEND=udocker
#ENV PIP_PYTHON_VERSION=${PYTHON_VERSION}

# install DNAnexus SDK and UA
RUN /opt/docker/install-dnanexus-cli.sh

ENV PATH="/google-cloud-sdk/bin:$PATH"
ENV CLOUDSDK_PYTHON=${MICROMAMBA_CONTAINING_PATH}/bin/python3
RUN /opt/docker/install-google-cloud-sdk.sh

# remove within-image helper scripts
RUN rm -rf /opt/docker

# ==============================================================================

# second stage build to "squash" layers from prior build
# NB: the environment variables must be set again for each build stage

# basing this build stage on the same base image rather than the empty 'scratch' base image
# is beneficial for image overlay systems that can diff and avoid copying identical files 
# during the copy-from-previous-build operation (i.e. containerd, possibly others)
FROM ubuntu:noble-20241118.1
# FROM scratch
ARG LANG LANGUAGE LC_ALL TZ MICROMAMBA_CONTAINING_PATH PYTHON_VERSION MAMBA_ROOT_PREFIX CONDA_PREFIX PATH MINIWDL__SCHEDULER__CONTAINER_BACKEND PATH CLOUDSDK_PYTHON

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
    CLOUDSDK_PYTHON="${CLOUDSDK_PYTHON}"

COPY --from=build  / /
#COPY --from=build /google-cloud-sdk /opt/micromamba /opt/dx-toolkit /

# set up entrypoint
CMD ["/bin/bash"]

