#!/bin/bash

set -e -o pipefail

# Silence some warnings about Readline. Checkout more over her
# https://github.com/phusion/baseimage-docker/issues/58
DEBIAN_FRONTEND=noninteractive
echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections

# Add some basics
apt-get update
apt-get install -y -qq --no-install-recommends apt-transport-https && apt-get update
# apt-get install -y -qq --no-install-recommends \
# 	lsb-release ca-certificates gnupg wget rsync curl python-is-python3 python3-pip bsdmainutils \
# 	python3-crcmod less nano vim git locales make bc \
# 	dirmngr parallel file \
# 	liblz4-tool pigz bzip2 lbzip2 zip unzip zstd xz-utils \
# 	fonts-dejavu

apt-get install -y -qq --no-install-recommends \
	lsb-release ca-certificates wget rsync curl bsdmainutils \
	less nano git locales make bc \
	parallel file \
	liblz4-tool pigz bzip2 lbzip2 zip unzip zstd xz-utils \
	fonts-dejavu

# Upgrade and clean
apt-get upgrade -y
apt-get autoremove -y
apt-get autoclean
apt-get clean
# remove package lists (these can be regenerated via apt-get update)
rm -rf /var/lib/apt/lists/*

locale-gen en_US.UTF-8
