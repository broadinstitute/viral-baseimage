#!/bin/bash

set -e -o pipefail

# Silence some warnings about Readline. Checkout more over her$
# https://github.com/phusion/baseimage-docker/issues/58
DEBIAN_FRONTEND=noninteractive

# Minimal ubnutu images need the following:
apt-get update
apt-get install -y -qq lsb-release

# phusion/baseimage is based on xenial, but in case something changes,
# auto-detect here:
DEBIAN_PLATFORM="$(lsb_release -c -s)"
echo "Debian platform: $DEBIAN_PLATFORM"

echo "deb http://packages.cloud.google.com/apt cloud-sdk-$DEBIAN_PLATFORM main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -

apt-get install -y -qq --no-install-recommends \
	ca-certificates wget rsync curl \
	python-crcmod less nano vim git locales make \
	google-cloud-sdk awscli \
	liblz4-tool pigz bzip2 lbzip2
apt-get upgrade -y
apt-get clean

locale-gen en_US.UTF-8
