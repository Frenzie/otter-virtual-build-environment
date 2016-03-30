#!/usr/bin/env bash
## build-otter-deb.sh
# Given the right prerequisites, this script will automatically create Otter
# DEB files.

if [ "$(whoami)" = "root" ]; then
	sudo -u vagrant "$0" "$@"
	exit 0
fi

version=0.1
help="You probably shouldn't be using this if you need help. Sorry. :-)"

echo_help() {
	echo "${help}"
	exit 1
}

echo_version() {
	echo "${version_info}"
	exit 1
}

## Process flags
# Thanks to http://stackoverflow.com/a/9899366
# This shows how to handle combined short options along with
# other long and short options. It does so by splitting them
# apart (e.g. 'tar -xvzf ...' -> 'tar -x -v -z -f ...')

while test $# -gt 0
do
	case $1 in

	# Normal option processing
		-h | --help)
			# usage and help
			echo_help
			;;
		-v | --version)
			# version info
			echo_version
			;;
		-e | --email)
			if [ -z "$2" ]; then
				echo_error "$1 requires an e-mail address in the from of 'name <name@domain.org>'."
			else
				export DEBEMAIL=$2
				shift
			fi
			;;
		-s | --suffix)
			if [ -z "$2" ]; then
				echo_error "$1 requires a DEB version suffix."
			else
				VERSION_SUFFIX=$2
				shift
			fi
			;;
	# ...

	# Special cases
		--)
			break
			;;
		--*)
			# error unknown (long) option $1
			echo_error "unknown (long) option $1"
			;;
		-?)
			# error unknown (short) option $1
			echo_error "unknown (short) option $1"
			;;

	# FUN STUFF HERE:
	# Split apart combined short options
		-*)
			split=$1
			shift
			set -- "$(echo "$split" | cut -c 2- | sed 's/./-& /g')" "$@"
			continue
			;;

	# Done with options
		*)
			break
			;;
	esac

	# for testing purposes:
	echo "testing $1"

	shift
done

# Use all CPUs
export MAKEFLAGS='-j$(nproc)'

# Make sure system is up to date
sudo apt-get update
sudo apt-get dist-upgrade -y
sudo apt-get autoclean
sudo apt-get autoremove

cd otter-build

# Make sure Otter is present and up to date
if cd otter-browser >/dev/null; then
	git pull
else
	git clone https://github.com/OtterBrowser/otter-browser.git
	cd otter-browser
fi

DATE=$(date -u +%Y%m%d.%H%M)

MAJOR_VERSION=$(grep MAJOR_VERSION CMakeLists.txt | grep -Eo "([0-9].?)*" | grep -Eo "[^\"]*")
MINOR_VERSION=$(grep MINOR_VERSION CMakeLists.txt | grep -Eo "([0-9].?)*" | grep -Eo "[^\"]*")
PATCH_VERSION=$(grep PATCH_VERSION CMakeLists.txt | grep -Eo "([0-9].?)*" | grep -Eo "[^\"]*")
OTTER_VERSION_MAIN=${MAJOR_VERSION}.${MINOR_VERSION}.${PATCH_VERSION}
OTTER_VERSION_CONTEXT=$(grep OTTER_VERSION_CONTEXT CMakeLists.txt | grep -Eo "\"([^\"]*)\"" | grep -Eo "[^\"]*")
OTTER_GIT_REVISION=$(git rev-parse --short HEAD)

CPACK_DEBIAN_PACKAGE_SECTION=$(grep CPACK_DEBIAN_PACKAGE_SECTION CMakeLists.txt | grep -Eo "\"([^\"]*)\"" | grep -Eo "[^\"]*")

if [ -n "${VERSION_SUFFIX}" ]; then
	OTTER_VERSION=${OTTER_VERSION_MAIN}${VERSION_SUFFIX}
else
	OTTER_VERSION=${OTTER_VERSION_MAIN}+${DATE}.git.${OTTER_GIT_REVISION}
fi
# Needs something like -1 at the end
OTTER_VERSION_DEBIAN=${OTTER_VERSION}-1

echo $OTTER_VERSION

OTTER_BUILD_DIR=otter-browser-${OTTER_VERSION}

cd ..

cp -r otter-browser ${OTTER_BUILD_DIR}

mv ${OTTER_BUILD_DIR}/packaging/debian ${OTTER_BUILD_DIR}/debian
#rm -r ${OTTER_BUILD_DIR}/packaging

# make changes to packaging
cd ${OTTER_BUILD_DIR}
# change empty message to something more meaningful?
debchange "" --newversion ${OTTER_VERSION_DEBIAN}

# Sanity checks
# Just output warning(s); don't attempt to autofix
SECTION_CHECK="Section: ${CPACK_DEBIAN_PACKAGE_SECTION}"
if ! grep "${SECTION_CHECK}" debian/control; then
	echo "Expected '${SECTION_CHECK}' but got '$(grep "Section:" debian/control )'"
fi
cd ..

# create source tarballs
tar cfJ otter-browser_${OTTER_VERSION_DEBIAN}.debian.tar.xz -C ${OTTER_BUILD_DIR} debian
tar cfJ otter-browser_${OTTER_VERSION}.orig.tar.xz ${OTTER_BUILD_DIR} --exclude .git

cd ${OTTER_BUILD_DIR}

# unsigned build
debuild -us -uc

# signed build
#debuild -S

# build i386 package
sudo sbuild-update -udcar stable-i386
sbuild -d stable --arch=i386
