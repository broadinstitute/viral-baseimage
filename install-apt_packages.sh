#!/bin/bash

set -e -o pipefail

# Silence some warnings about Readline. Checkout more over her
# https://github.com/phusion/baseimage-docker/issues/58
DEBIAN_FRONTEND=noninteractive
echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections

# Add some basics
apt-get update
apt-get install -y -qq --no-install-recommends apt-transport-https && apt-get update
apt-get install -y -qq --no-install-recommends \
	lsb-release ca-certificates gnupg wget rsync curl python-is-python3 python3-pip bsdmainutils \
	python3-crcmod less nano vim git locales make bc \
	dirmngr parallel file \
	liblz4-tool pigz bzip2 lbzip2 zip unzip zstd xz-utils \
	fonts-dejavu

## Auto-detect platform
#DEBIAN_PLATFORM="$(lsb_release -c -s)"
#echo "Debian platform: $DEBIAN_PLATFORM"
#DEBIAN_PLATFORM=bionic
#echo "faking bionic release for google cloud sdk"

# Add source for gcloud sdk
echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -

# Install gcloud and aws
apt-get update
apt-get install -y -qq --no-install-recommends \
	google-cloud-cli awscli

# Upgrade and clean
apt-get upgrade -y
apt-get clean

locale-gen en_US.UTF-8
