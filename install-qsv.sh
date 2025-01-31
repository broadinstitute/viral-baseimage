#!/bin/bash

# This installs qsv:
#   "a command line program for querying, indexing, slicing, analyzing, filtering, enriching,
#    transforming, sorting, validating & joining CSV files"
#
# Additional information available here:
#   https://github.com/jqnatividad/qsv
#
# Additional information on available releases (including the latest versions) available here:
#   https://github.com/jqnatividad/qsv/releases

QSV_BINARY=qsvpy310 # "qsv" is the binary with all features enabled (except python); "qsvlite" has extra features disabled and is much smaller in size
QSV_VERSION=2.2.1

case "$(uname -m)" in
  x86_64)
    CPU_ARCH="x86_64"
    ;;
  arm64 | aarch64)
    CPU_ARCH="aarch64" #"aarch64" for Apple Silicon and other ARM-based CPUs
    ;;
  *)
    CPU_ARCH="unknown"
    echo "Unknown CPU architecture returned by uname -m: '${CPU_ARCH}'" >&2
    exit 1
    ;;
esac

case "$(uname -s)" in
  Linux)
    OS_BUILD_TYPE="unknown-linux-gnu" # "unknown-linux-musl" for Linux platforms where libc compatability is an issue, otherwise "unknown-linux-gnu"
    ;;
  Darwin)
    OS_BUILD_TYPE="apple-darwin"
    ;;
  *)
    OS_BUILD_TYPE="unknown"
    echo "Unknown OS type returned by uname -s: '${OS_BUILD_TYPE}'" >&2
    exit 1
    ;;
esac

if ! command -v curl &> /dev/null; then
    echo "curl is required but it does not appear to be installed" >&2
    exit 1
fi

PACKAGE_ZIP=qsv-${QSV_VERSION}-${CPU_ARCH}-${OS_BUILD_TYPE}.zip

echo "Downloading binary for ${OS_BUILD_TYPE} built for ${CPU_ARCH}: ${PACKAGE_ZIP}"
curl --silent --location --output $PACKAGE_ZIP https://github.com/jqnatividad/qsv/releases/download/${QSV_VERSION}/${PACKAGE_ZIP}

# unzip only the qsv binary to its final location (the zip archive also contains alternate builds)
unzip -o -d /usr/local/bin $PACKAGE_ZIP ${QSV_BINARY}
rm $PACKAGE_ZIP

chmod 755 /usr/local/bin/${QSV_BINARY}

# if copying in an alternate build of qsv, symlink it to "qsv"
if [[ "$QSV_BINARY" != "qsv" ]]; then
    if [ ! -f /usr/local/bin/qsv ]; then
        ln -s /usr/local/bin/${QSV_BINARY} /usr/local/bin/qsv
    fi
fi

hash -r

if ! command -v qsv &> /dev/null; then
    echo "The qsv installation seems to have failed" >&2
    exit 1
else
    echo "qsv installation successful."
fi

