#!/bin/bash
set -e -o pipefail

UDOCKER_PATH=/usr/local/udocker
UDOCKER_VERSION=1.3.16

curl -L https://github.com/indigo-dc/udocker/releases/download/$UDOCKER_VERSION/udocker-$UDOCKER_VERSION.tar.gz \
 | tar -xzv
mv udocker-$UDOCKER_VERSION/udocker /usr/local
ln -s /usr/local/udocker/udocker /usr/local/bin/

#cd $UDOCKER_PATH
#udocker install
