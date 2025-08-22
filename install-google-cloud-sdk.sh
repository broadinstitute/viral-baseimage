#!/usr/bin/env bash


# Install google-cloud-sdk manually rather than via the apt package to save space
# See: https://github.com/GoogleCloudPlatform/gsutil/issues/1732#issuecomment-2029591598

ARCH=$(uname -m)
CLOUD_SDK_VERSION="521.0.0"

#GOOGLE_CLOUD_CLI_PATH="${GOOGLE_CLOUD_CLI_PATH:-/opt/google-cloud-sdk}"

echo "Installing google-cloud-cli to GOOGLE_CLOUD_CLI_PATH: ${GOOGLE_CLOUD_CLI_PATH}" #&& exit 1
echo "CLOUDSDK_PYTHON: ${CLOUDSDK_PYTHON}"
mkdir -p ${GOOGLE_CLOUD_CLI_PATH}

# extract to $GOOGLE_CLOUD_CLI_PATH, omitting the top-level directory of the archive (typically "google-cloud-sdk/")
#  the GOOGLE_CLOUD_CLI_PATH environment variable is set in the Dockerfile (new default location:" /opt/google-cloud-sdk")
curl --silent https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-${CLOUD_SDK_VERSION}-linux-${ARCH}.tar.gz | tar -xzp -C "${GOOGLE_CLOUD_CLI_PATH}" --strip-components=1

hash -r

gcloud config set core/disable_usage_reporting           true
gcloud config set component_manager/disable_update_check true

gcloud config set --installation component_manager/disable_update_check true

gcloud components update

# List of components: 
#   https://cloud.google.com/sdk/docs/components
gcloud components remove -q bq # BigQuery API CLI is installed by default and can be removed (until needed)
#gcloud components remove -q alpha beta # remove alpha and beta commands

gcloud components update
rm -rf $(find "${GOOGLE_CLOUD_CLI_PATH}/" -regex ".*/__pycache__")
rm -rf ${GOOGLE_CLOUD_CLI_PATH}/.install/.backup
rm "${GOOGLE_CLOUD_CLI_PATH}/RELEASE_NOTES"

# remove AWS-specific CLI specification data from google-cloud-sdk installation
rm -rf "${GOOGLE_CLOUD_CLI_PATH}/lib/third_party/botocore/data"

# remove the version of python bundled with google-cloud-sdk
# since we have the system-level one and/or one from (mini)conda/(micro)mamba
# Some day it may be possible to remove it this way (not currently):
# gcloud components remove bundled-python3-unix
rm -rf "${GOOGLE_CLOUD_CLI_PATH}/platform/bundledpythonunix"
hash -r

# Until we know if the relocation of the sdk to the env var-specified path
# is a breaking change, symlink from the old path to the new
ln -s "${GOOGLE_CLOUD_CLI_PATH}" /google-cloud-sdk

# report the version
gcloud --version