FROM ubuntu:noble-20250404

LABEL maintainer="viral-ngs team <viral-ngs@broadinstitute.org>"

# define path of helper files within container
# this can be overridden during docker build by setting '--build-args BASEIMAGE_SETUP_SCRIPT_PATH_IN_CONTAINER="$OVERRIDE_VALUE"'
ARG BASEIMAGE_SETUP_SCRIPT_PATH_IN_CONTAINER=/opt/docker

COPY install-*.sh postinstall-*.sh requirements-*.txt ${BASEIMAGE_SETUP_SCRIPT_PATH_IN_CONTAINER}/

# System packages, Google Cloud CLI, and locale
# ca-certificates and wget needed for gosu
# bzip2, liblz4-toolk, and pigz are useful for packaging and archival
# google-cloud-cli needed when using this in GCE

# to enable nala (performance-optimized interface to libapt)
#   set:
#     NALA_AS_INSTALLER=true NALA_BENCHMARK_MIRRORS=true
RUN BENCHMARK_MIRRORS=true ${BASEIMAGE_SETUP_SCRIPT_PATH_IN_CONTAINER}/install-apt_packages.sh ${BASEIMAGE_SETUP_SCRIPT_PATH_IN_CONTAINER}/requirements-system-packages.txt && \
    ${BASEIMAGE_SETUP_SCRIPT_PATH_IN_CONTAINER}/install-apt_external_repo_keys.sh && \
    ${BASEIMAGE_SETUP_SCRIPT_PATH_IN_CONTAINER}/install-apt_packages.sh ${BASEIMAGE_SETUP_SCRIPT_PATH_IN_CONTAINER}/requirements-system-packages-from-nonstandard-sources.txt && \
    ${BASEIMAGE_SETUP_SCRIPT_PATH_IN_CONTAINER}/postinstall-cleanup_apt_packages.sh ${BASEIMAGE_SETUP_SCRIPT_PATH_IN_CONTAINER}/requirements-system-packages-to-remove-after-build.txt

# Set default locale to en_US.UTF-8
ENV LANG="en_US.UTF-8" LANGUAGE="en_US:en" LC_ALL="en_US.UTF-8" TZ="UTC"

# install udocker
RUN ${BASEIMAGE_SETUP_SCRIPT_PATH_IN_CONTAINER}/install-udocker.sh

# install DNAnexus SDK and UA
RUN ${BASEIMAGE_SETUP_SCRIPT_PATH_IN_CONTAINER}/install-dnanexus-cli.sh

# install qsv (binary for manipulation and query of tabular data files like tsv)
RUN ${BASEIMAGE_SETUP_SCRIPT_PATH_IN_CONTAINER}/install-qsv.sh

# install miniconda3 with our default channels and no other packages
ENV MINICONDA_PATH="/opt/miniconda"
RUN ${BASEIMAGE_SETUP_SCRIPT_PATH_IN_CONTAINER}/install-miniforge-conda.sh ${BASEIMAGE_SETUP_SCRIPT_PATH_IN_CONTAINER}/requirements-conda-base-env.txt

# install miniwdl
#RUN pip3 install miniwdl==1.11.1
ENV MINIWDL__SCHEDULER__CONTAINER_BACKEND=udocker

# set up entrypoint
ENV PATH="$MINICONDA_PATH/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
CMD ["/bin/bash"]

