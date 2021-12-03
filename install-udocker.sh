#!/bin/bash
set -e -o pipefail

UDOCKER_PATH=/usr/local/udocker
UDOCKER_VERSION=1.3.1

curl -L https://github.com/indigo-dc/udocker/releases/download/v$UDOCKER_VERSION/udocker-$UDOCKER_VERSION.tar.gz \
  | tar -xzv
mv udocker /usr/local

export PATH=$UDOCKER_PATH:$PATH
hash -r

cd $UDOCKER_PATH
udocker install
