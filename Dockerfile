FROM ubuntu:jammy-20230126

LABEL maintainer "viral-ngs team <viral-ngs@broadinstitute.org>"

COPY install-*.sh /opt/docker/

# System packages, Google Cloud CLI, and locale
# ca-certificates and wget needed for gosu
# bzip2, liblz4-toolk, and pigz are useful for packaging and archival
# google-cloud-cli needed when using this in GCE
RUN /opt/docker/install-apt_packages.sh

# Set default locale to en_US.UTF-8
ENV LANG="en_US.UTF-8" LANGUAGE="en_US:en" LC_ALL="en_US.UTF-8" TZ="UTC"

# install miniwdl
RUN pip3 install miniwdl==1.8.0
ENV MINIWDL__SCHEDULER__CONTAINER_BACKEND=udocker

# install udocker
RUN /opt/docker/install-udocker.sh

# install DNAnexus SDK and UA
RUN /opt/docker/install-dnanexus-cli.sh

# install qsv (binary for manipulation and query of tabular data files like tsv)
RUN /opt/docker/install-qsv.sh

# install miniconda3 with our default channels and no other packages
ENV MINICONDA_PATH="/opt/miniconda"
RUN /opt/docker/install-miniconda.sh

# set up entrypoint
ENV PATH="$MINICONDA_PATH/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
CMD ["/bin/bash"]

