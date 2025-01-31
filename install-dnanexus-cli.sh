#!/bin/bash

set -e -o pipefail -u

#DX_TOOLKIT_VERSION=0.388.0
DX_UPLOAD_AGENT_VERSION=1.5.33

# get the dx-toolkit
#curl -s https://dnanexus-sdk.s3.amazonaws.com/dx-toolkit-v${DX_TOOLKIT_VERSION}-ubuntu-16.04-amd64.tar.gz | tar -xzp

# install dxpy via pip, as suggested by the DNAnexus README.md
#   pip install options:
#     https://pip.pypa.io/en/stable/cli/pip_install/#options
#pip install dxpy
#pip cache purge

#get and install the dnanexus upload agent (ua agent)
mkdir -p /opt/dx-toolkit/bin
curl -s https://dnanexus-sdk.s3.amazonaws.com/dnanexus-upload-agent-${DX_UPLOAD_AGENT_VERSION}-linux.tar.gz | tar -xzp
mv dnanexus-upload-agent-${DX_UPLOAD_AGENT_VERSION}-linux/ua /opt/dx-toolkit/bin/ua
rmdir dnanexus-upload-agent-${DX_UPLOAD_AGENT_VERSION}-linux
