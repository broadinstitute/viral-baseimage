#!/bin/bash

# Install google-cloud-sdk manually rather than via the apt package to save space
# See: https://github.com/GoogleCloudPlatform/gsutil/issues/1732#issuecomment-2029591598

ARCH=$(arch)
CLOUD_SDK_VERSION="471.0.0"

curl --silent -O https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-${CLOUD_SDK_VERSION}-linux-${ARCH}.tar.gz

tar xzf google-cloud-cli-${CLOUD_SDK_VERSION}-linux-${ARCH}.tar.gz

rm google-cloud-cli-${CLOUD_SDK_VERSION}-linux-${ARCH}.tar.gz

gcloud config set core/disable_usage_reporting true
gcloud config set component_manager/disable_update_check true

# List of components: 
#   https://cloud.google.com/sdk/docs/components
gcloud components remove bq # BigQuery API CLI is installed by default and can be removed (until needed)

gcloud components update
rm -rf $(find google-cloud-sdk/ -regex ".*/__pycache__")
rm -rf google-cloud-sdk/.install/.backup

# remove the version of python bundled with google-cloud-sdk
# since we have the system-level one and/or one from (mini)conda/(micro)mamba
# Some day it may be possible to remove it this way (not currently):
# gcloud components remove bundled-python3-unix
rm -rf google-cloud-sdk/platform/bundledpythonunix
hash -r

gcloud --version