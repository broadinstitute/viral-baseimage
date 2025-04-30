#!/bin/bash

APT_PKGMGR_OPTS=(
    "--assume-yes"
    "--quiet=2"
)
if command -v apt-fast &> /dev/null; then
    APT_PKGMGR_CMD="apt-fast"
else
    APT_PKGMGR_CMD="apt-get"
fi

# if $1 is defined, use it as the list of packages to remove
#
# Note: to see which packages depend on the presence of an installed package, use:
#   apt-cache rdepends --installed $packagename
# Note: to see which packages an installed package depends on, use:
#   apt-cache depends --installed $packagename
if [[ ! -z "$1" ]]; then
    # remove system installation-related packages listed in $APT_PACKAGES_TO_REMOVE_LIST_FILE
    APT_PACKAGES_TO_REMOVE_LIST_FILE="$1"
    mapfile -t pkgs < <(grep -E -v '^(#[^\n]*)$' "$APT_PACKAGES_TO_REMOVE_LIST_FILE")
    apt-get remove ${APT_PKGMGR_OPTS[*]} --autoremove ${pkgs[*]}
fi

# Upgrade and clean
$APT_PKGMGR_CMD update
$APT_PKGMGR_CMD upgrade ${APT_PKGMGR_OPTS[*]}

$APT_PKGMGR_CMD autoremove ${APT_PKGMGR_OPTS[*]}
$APT_PKGMGR_CMD clean

# if the 'apt-fast' package manager wrapper is available, remove it to reduce the size of the docker image
# (apt-fast is a performance-optimized wrapper around apt)
if ! command -v apt-fast &> /dev/null; then
    apt-get remove --assume-yes --quiet=2 apt-fast
    # one final cleanup
    apt-get autoremove --assume-yes --quiet=2 && \
        apt-get clean --quiet=2
fi

locale-gen en_US.UTF-8
