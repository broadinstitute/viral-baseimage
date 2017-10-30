FROM phusion/baseimage:0.9.22

LABEL maintainer "Chris Tomkins-Tinch <tomkinsc@broadinstitute.org>"

COPY Dockerfile install-*.sh /opt/docker/
RUN chmod a+x /opt/docker/*.sh

# Silence some warnings about Readline. Checkout more over here:
# https://github.com/phusion/baseimage-docker/issues/58
ENV DEBIAN_FRONTEND noninteractive


##############################
# System packages, Google Cloud SDK, and locale
##############################
# ca-certificates and wget needed for gosu
# bzip2, liblz4-toolk, and pigz are useful for packaging and archival
# google-cloud-sdk needed when using this in GCE, xenial is what phusion/baseimage is based on
# 
RUN echo "deb http://packages.cloud.google.com/apt cloud-sdk-xenial main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list \
    && curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add - \
    && apt-get update \
    && apt-get install -y -qq --no-install-recommends ca-certificates wget rsync curl bzip2 python less nano vim git locales google-cloud-sdk awscli liblz4-tool pigz \
    && apt-get upgrade -y \
    && apt-get clean \
    && locale-gen en_US.UTF-8

# skip this...
# removing /var/lib/apt/lists/* frees some space
#RUN rm -rf /var/lib/apt/lists/*

# Set default locale to en_US.UTF-8
ENV LANG="en_US.UTF-8" LANGUAGE="en_US:en" LC_ALL="en_US.UTF-8"

# install DNAnexus SDK and UA
RUN /opt/docker/install-dnanexus-cli.sh

# grab gosu for easy step-down from root
RUN /opt/docker/install-gosu.sh

# install miniconda3 with our default channels and no other packages
ENV MINICONDA_PATH="/opt/miniconda"
RUN /opt/docker/install-miniconda.sh

# Silence some warnings about Readline. Checkout more over here:
# https://github.com/phusion/baseimage-docker/issues/58
ENV DEBIAN_FRONTEND teletype
