#!/bin/bash

set -e -o pipefail -u

DX_TOOLKIT_VERSION=0.285.0
DX_UPLOAD_AGENT_VERSION=1.5.31

# get the dx-toolkit
curl -s https://dnanexus-sdk.s3.amazonaws.com/dx-toolkit-v${DX_TOOLKIT_VERSION}-ubuntu-14.04-amd64.tar.gz | tar -xzp

#get the ua
curl -s https://dnanexus-sdk.s3.amazonaws.com/dnanexus-upload-agent-${DX_UPLOAD_AGENT_VERSION}-linux.tar.gz | tar -xzp
mv dnanexus-upload-agent-${DX_UPLOAD_AGENT_VERSION}-linux/ua dx-toolkit/bin
rmdir dnanexus-upload-agent-${DX_UPLOAD_AGENT_VERSION}-linux

# install in /opt/dx-toolkit
mkdir -p /opt
mv dx-toolkit /opt
