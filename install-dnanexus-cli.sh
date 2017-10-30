#!/bin/bash

# get the dx-toolkit
curl -s https://wiki.dnanexus.com/images/files/dx-toolkit-v0.237.0-ubuntu-14.04-amd64.tar.gz | tar -xzp

#get the ua
curl -s https://wiki.dnanexus.com/images/files/dnanexus-upload-agent-1.5.29-linux.tar.gz | tar -xzp
mv dnanexus-upload-agent-1.5.29-linux/ua dx-toolkit/bin
rmdir dnanexus-upload-agent-1.5.29-linux

# install in /opt/dx-toolkit
mkdir -p /opt
mv dx-toolkit /opt
