FROM ubuntu:artful-20180412

LABEL maintainer "Chris Tomkins-Tinch <tomkinsc@broadinstitute.org>"

COPY install-*.sh /opt/docker/

# System packages, Google Cloud SDK, and locale
# ca-certificates and wget needed for gosu
# bzip2, liblz4-toolk, and pigz are useful for packaging and archival
# google-cloud-sdk needed when using this in GCE
RUN /opt/docker/install-apt_packages.sh

# Set default locale to en_US.UTF-8
ENV LANG="en_US.UTF-8" LANGUAGE="en_US:en" LC_ALL="en_US.UTF-8"

# install DNAnexus SDK and UA
RUN /opt/docker/install-dnanexus-cli.sh

# grab gosu for easy step-down from root
RUN /opt/docker/install-gosu.sh

# install miniconda3 with our default channels and no other packages
ENV MINICONDA_PATH="/opt/miniconda"
RUN /opt/docker/install-miniconda.sh

# set up entrypoint
ENV PATH="$MINICONDA_PATH/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
CMD ["/bin/bash"]
