#!/bin/bash
set -e -o pipefail

UDOCKER_PATH=/usr/local/udocker
UDOCKER_VERSION=1.3.7

curl -L https://github.com/indigo-dc/udocker/releases/download/$UDOCKER_VERSION/udocker-$UDOCKER_VERSION.tar.gz \
 | tar -xzv
mv udocker-$UDOCKER_VERSION/udocker /usr/local

echo '#!/bin/bash' > /usr/local/bin/udocker
echo '/usr/local/udocker/udocker --allow-root "$@"' >> /usr/local/bin/udocker
chmod +x /usr/local/bin/udocker

#cd $UDOCKER_PATH
#udocker install
