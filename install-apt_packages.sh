#!/bin/bash

set -x -e -o pipefail

RETRIES=3
RETRY_DELAY=5
RETRY_FACTOR=2

# Silence some warnings about Readline. Checkout more over her
# https://github.com/phusion/baseimage-docker/issues/58
export DEBIAN_FRONTEND=noninteractive
echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections

# packages related to installing *other* packages
PKGS_USED_DURING_APT_INSTALLATION=(
	"curl"
	"ca-certificates"
	"apt-transport-https"
	"software-properties-common"
	"gnupg"
)

APT_PKGMGR_OPTS=(
	"--assume-yes"
	"--no-install-recommends"
	"--quiet=2"
	#"--purge"
)

install_apt_pkgs(){
	pkgs=($@)

	APT_PKGMGR_CMD="apt-get"
	if command -v apt-fast &> /dev/null; then
		APT_PKGMGR_CMD="apt-fast"
	fi

	$APT_PKGMGR_CMD update

	pkgs_already_installed=()
	pkgs_to_install=()
	if (( ${#pkgs[@]} > 0 )); then
		# for each package in $pkgs, check if it is already installed
		# and exclude from the installation array if so
		for i in "${!pkgs[@]}"; do
			if dpkg -s "${pkgs[$i]}" &> /dev/null; then
				pkgs_already_installed+=("${pkgs[$i]}")
			else
				pkgs_to_install+=("${pkgs[$i]}")
			fi
		done

		# if there are any packages left in the array, install them
		if (( ${#pkgs_to_install[@]} > 0 )); then
			echo "Installing ${#pkgs_to_install[@]} apt packages:"
			printf "Installing %s apt package%s:\n" \
				"${#pkgs_to_install[@]}" \
				"$([ "${#pkgs_to_install[@]}" -eq 1 ] || echo s)"
			for pkg in "${pkgs_to_install[@]}"; do
				printf "\t$pkg\n"
			done
			# if one or more packages is being skipped, notify the user
			if (( ${#pkgs_already_installed[@]} > 0 )); then
				printf "The following %s package%s %s already installed and will be skipped:\n" \
					"${#pkgs_already_installed[@]}" \
					"$([ "${#pkgs_already_installed[@]}" -eq 1 ] || echo s)" \
					"$([ "${#pkgs_already_installed[@]}" -eq 1 ] && echo 'is' || echo 'are')"
				for pkg in "${pkgs_already_installed[@]}"; do
					printf "\t$pkg\n"
				done
			fi
		else
			echo "All apt packages already installed:"
			for pkg in "${pkgs[@]}"; do
				printf "\t$pkg\n"
			done
			return 0
		fi
	fi
	
	# ============== PACKAGE INSTALLATION ==============
	for ((i=1; i<=$RETRIES; i++)); do
		# install the packages specified in the requirements file
		if $APT_PKGMGR_CMD install \
							${APT_PKGMGR_OPTS[*]} \
							"${pkgs_to_install[@]}"; then
			return 0
		else
			if [ $i -eq $RETRIES ]; then
				echo "'$APT_PKGMGR_CMD install' failed after $RETRIES attempts; exiting..."
				return 1
			fi
			# alert the user that the command failed and is being retried
			# and sleep, RETRY_DELAY with an exponential back-off specified by RETRY_FACTOR
			time_to_sleep=$((RETRY_DELAY * (RETRY_FACTOR*(i))))
			echo "'$APT_PKGMGR_CMD install' failed; retrying in $time_to_sleep seconds..."
			sleep $time_to_sleep
		fi
	done
	# ==================================================
}

# ----- install installation tools -----
install_apt_pkgs ${PKGS_USED_DURING_APT_INSTALLATION[*]}

# ----- determine fastest mirrors for apt -----
# install fast-apt-mirror.sh
# see:
#   https://github.com/vegardit/fast-apt-mirror.sh

# if /usr/local/bin/fast-apt-mirror.sh does not exist, assume we need to install it and determine the fastest mirror
if [ "$BENCHMARK_MIRRORS" == "true" ]; then
	if [ ! -f /usr/local/bin/fast-apt-mirror.sh ]; then
		# if the script is already present, skip this step
		curl -fsSL https://raw.githubusercontent.com/vegardit/fast-apt-mirror.sh/1.4.0/fast-apt-mirror.sh -o /usr/local/bin/fast-apt-mirror.sh && \
		chmod 755 /usr/local/bin/fast-apt-mirror.sh
	fi

	# backup the source repo (mirror) list
	mv /etc/apt/sources.list /etc/apt/sources.list.bak
	
	set +e
	for ((i=1; i<=$RETRIES; i++)); do
		# docs for fast-apt-mirror.sh:
		#   https://github.com/vegardit/fast-apt-mirror.sh?tab=readme-ov-file#the-find-sub-command
		if  /usr/local/bin/fast-apt-mirror.sh find --apply \
												   --sample-size 1024 \
												   --healthchecks 20 \
												   --speedtests 6 \
												   --parallel 1 \
												   --sample-time 3; then
			break
		else
			if [ $i -eq $RETRIES ]; then
				echo "fast-apt-mirror.sh failed after $RETRIES attempts; using default sources.list"
				mv /etc/apt/sources.list.bak /etc/apt/sources.list
				break
			fi
			# alert the user that the command failed and is being retried
			# and sleep, RETRY_DELAY with an exponential back-off specified by RETRY_FACTOR
			time_to_sleep=$((RETRY_DELAY * (RETRY_FACTOR*(i))))
			echo "'fast-apt-mirror.sh fetch' failed; retrying in $time_to_sleep seconds..."
			sleep $time_to_sleep
		fi
	done
	set -e
fi

# ----- install apt-fast, performance-optimized wrapper around apt-get -----
# if 'apt-fast' command is not available, install and configure it
# see:
#   https://github.com/ilikenwf/apt-fast?tab=readme-ov-file#manual
if ! command -v apt-fast &> /dev/null; then
	add-apt-repository --yes ppa:apt-fast/stable

	install_apt_pkgs apt-fast

	echo debconf apt-fast/maxdownloads string 20      | debconf-set-selections
	echo debconf apt-fast/dlflag       boolean true   | debconf-set-selections
	echo debconf apt-fast/aptmanager   string apt-get | debconf-set-selections
fi

if command -v apt-fast &> /dev/null; then
	APT_PKGMGR_CMD="apt-fast"
else
    APT_PKGMGR_CMD="apt-get"
fi

# if multiple arguments are passed to this script, 
# treat them as an array of file paths, with each path referring to a text file 
# containing a list of apt packages to install.
# A package invocation command will be run for each file specified, one per file (i.e. the requirements are installed sequentially by file to allow staged installation)
if [ "$#" -gt 0 ]; then
	for FILE in "$@"; do
		if [ -f "$FILE" ]; then
			REQUIREMENTS_FILE=$FILE
			echo "Installing apt packages from $(realpath $REQUIREMENTS_FILE):"

			mapfile -t pkgs < <(grep -E -v '^(#.*)?$' "$REQUIREMENTS_FILE")

			# install the packages specified in the requirements file (excluding any identified as already being present)
			if install_apt_pkgs ${pkgs[*]}; then
				echo "'$APT_PKGMGR_CMD install' succeeded for requirements file $(basename ${REQUIREMENTS_FILE})..."
				continue
			else
				echo "'$APT_PKGMGR_CMD install' failed for requirements file $(basename ${REQUIREMENTS_FILE})..."
				exit 1
			fi
		else
			echo "No valid input file provided; skipping package installation." 
			echo "Check requirements file specified: $REQUIREMENTS_FILE"
			exit 1
		fi
	done
else
	echo "No valid input file provided; skipping package installation."
	echo "Usage: $0 <requirements_file1.txt> [<requirements_file2.txt> ...]"
	exit 0
fi
