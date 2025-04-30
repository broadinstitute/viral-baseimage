#!/bin/bash

set -x -e -o pipefail

mkdir -p /etc/apt/keyrings /usr/share/keyrings

## Auto-detect platform
#DEBIAN_PLATFORM="$(lsb_release -c -s)"
#echo "Debian platform: $DEBIAN_PLATFORM"
#DEBIAN_PLATFORM=bionic
#echo "faking bionic release for google cloud sdk"

# Add source for gcloud sdk
local_pgp_key_path="/usr/share/keyrings/cloud.google.gpg"
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | gpg --batch --yes --dearmor -o ${local_pgp_key_path}
echo "deb [signed-by=${local_pgp_key_path}] https://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list

# # Add source for apt-fast
#local_pgp_key_path="/etc/apt/keyrings/apt-fast.gpg"
#curl -fsSL "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0xBC5934FD3DEBD4DAEA544F791E2824A7F22B44BD" |gpg --batch --yes --dearmor -o ${local_pgp_key_path}
# echo "deb [signed-by=${local_pgp_key_path}] http://ppa.launchpad.net/apt-fast/stable/ubuntu noble main" | tee /etc/apt/sources.list.d/apt-fast.list

apt-get update