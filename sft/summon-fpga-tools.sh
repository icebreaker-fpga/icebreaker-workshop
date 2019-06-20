#!/bin/bash
# 
# Summon FPGA Tools build script
# Written by Piotr Esden-Tempski <piotr@esden.net>, released as public domain.
#
# To the extent possible under law, the author(s) have dedicated all copyright
# and related and neighboring rights to this software to the public domain
# worldwide. This software is distributed without any warranty.
#
# You should have received a copy of the CC0 Public Domain Dedication along
# with this software. If not, see <http://creativecommons.org/publicdomain/zero/1.0/>. 

#
# TODO: this should be automatically detected and the deps should be installed when needed.
#
# Requirements are all listed in the accompanying README.md file.
#

# Stop if any command fails
set -e

##############################################################################
# Default settings section
# You probably want to customize those
# You can also pass them as parameters to the script
##############################################################################
PREFIX=${HOME}/sft	# Install location of your final fpga tools
# We do not support MacPorts only homebrew for the time being...
#DARWIN_OPT_PATH=/usr/local	# Path in which MacPorts or Fink is installed
# Set to 'sudo' if you need superuser privileges while installing
SUDO=
# Set to 1 to be quieter while running
QUIET=0
# default to not being verbose
VERBOSE=
# Set to 'master' or a git revision number to use instead of stable version
ICESTORM_EN=1
ICESTORM_GIT=master
PRJTRELLIS_EN=0
PRJTRELLIS_GIT=master
ARACHNEPNR_EN=0
ARACHNEPNR_GIT=master
NEXTPNR_ICE40_EN=1
NEXTPNR_ECP5_EN=0
NEXTPNR_GIT=master
NEXTPNR_BUILD_GUI=on
YOSYS_EN=1
YOSYS_GIT=master
YOSYS_CONFIG=
IVERILOG_EN=0
IVERILOG_GIT=v10-branch

# Override automatic detection of cpus to compile on
CPUS=

# FTP options ... some environments do not support non-passive FTP
# FETCH_NO_PASSIVE="--no-passive-ftp "
FETCH_NO_CERTCHECK="--no-check-certificate "

##############################################################################
# Parsing command line parameters
##############################################################################

while [ $# -gt 0 ]; do
	case $1 in
		PREFIX=*|\
		SUDO=*|\
		QUIET=*|\
		ICESTORM_GIT=*|\
		PRJTRELLIS_GIT=*|\
		ARACHNEPNR_GIT=*|\
		NEXTPNR_GIT=*|\
		YOSYS_GIT=*|\
		YOSYS_CONFIG=*|\
		IVERILOG_GIT=*|\
		CPUS=*|\
		NEXTPNR_BUILD_GUI=*|\
		VERBOSE=*\
		)
		eval $1
		;;
	  *)
		echo "Unknown parameter: $1"
		exit 1
		;;
	esac

	shift # shifting parameter list to access the next one
done

##############################################################################
# Version and download url settings section
##############################################################################

DEFAULT_ICESTORM=
DEFAULT_PRJTRELLIS=
DEFAULT_ARACHNEPNR=
DEFAULT_NEXTPNR=
DEFAULT_YOSYS=yosys-0.8
DEFAULT_IVERILOG_VERSION=v10_2
DEFAULT_IVERILOG=iverilog-${DEFAULT_IVERILOG_VERSION}

ICESTORM=${ICESTORM:-${DEFAULT_ICESTORM}}
PRJTRELLIS=${PRJTRELLIS:-${DEFAULT_PRJTRELLIS}}
ARACHNEPNR=${ARACHNEPNR:-${DEFAULT_ARACHNEPNR}}
NEXTPNR=${NEXTPNR:-${DEFAULT_NEXTPNR}}
YOSYS=${YOSYS:-${DEFAULT_YOSYS}}${IVERILOG}
IVERILOG_VERSION=${IVERILOG_VERSION:-${DEFAULT_IVERILOG_VERSION}}
IVERILOG=${IVERILOG:-${DEFAULT_IVERILOG}}

##############################################################################
# Print settings
##############################################################################

echo "Settings used for this build are:"
echo "PREFIX=$PREFIX"
echo "SUDO=$SUDO"
echo "QUIET=$QUIET"
echo "VERBOSE=$VERBOSE"
echo "ICESTORM=$ICESTORM"
echo "ICESTORM_GIT=$ICESTORM_GIT"
echo "PRJTRELLIS=$PRJTRELLIS"
echo "PRJTRELLIS_GIT=$PRJTRELLIS_GIT"
echo "ARACHNEPNR=$ARACHNEPNR"
echo "ARACHNEPNR_GIT=$ARACHNEPNR_GIT"
echo "NEXTPNR=$NEXTPNR"
echo "NEXTPNR_GIT=$NEXTPNR_GIT"
echo "YOSYS=$YOSYS"
echo "YOSYS_GIT=$YOSYS_GIT"
echo "YOSYS_CONFIG=$YOSYS_CONFIG"
echo "IVERILOG_VERSION=$IVERILOG_VERSION"
echo "IVERILOG=$IVERILOG"
echo "IVERILOG_GIT=$IVERILOG_GIT"
echo "CPUS=$CPUS"

##############################################################################
# Flags section
##############################################################################

if [ "x${CPUS}" == "x" ]; then
	if which getconf > /dev/null; then
		CPUS=$(getconf _NPROCESSORS_ONLN)
	else
		CPUS=1
	fi

	PARALLEL=-j$((CPUS + 1))
else
	PARALLEL=-j${CPUS}
fi

echo "${CPUS} cpu's detected running make with '${PARALLEL}' flag"

ICESTORMFLAGS=
PRJTRELLISFLAGS=
ARACHNEPNRFLAGS=
NEXTPNRFLAGS=
YOSYSFLAGS=

# Pull in the local configuration, if any
if [ -f local.sh ]; then
    . ./local.sh
fi

MAKEFLAGS=${PARALLEL}
TARFLAGS=v

if [ ${QUIET} != 0 ]; then
    TARFLAGS=
    MAKEFLAGS="${MAKEFLAGS} -s"
fi

export PATH="${PREFIX}/bin:${PATH}"

SUMMON_DIR=$(pwd)
SOURCES=${SUMMON_DIR}/sources
STAMPS=${SUMMON_DIR}/stamps


if [ "x${VERBOSE}" != "x" ]; then
     set -x
fi

##############################################################################
# Tool section
##############################################################################
TAR=tar

##############################################################################
# OS and Tooldetection section
# Detects which tools and flags to use
##############################################################################

case "$(uname)" in
	Linux)
	echo "Found Linux OS."
	;;
	Darwin)
	echo "Found Darwin OS."
	QT5_PREFIX="/usr/local/opt/qt5"
	PATH="/usr/local/opt/bison/bin:$PATH"
	LDFLAGS="-L/usr/local/opt/bison/lib"
	;;
	CYGWIN*)
	echo "Found CygWin that means Windows most likely."
	;;
	*)
	echo "Found unknown OS. Aborting!"
	exit 1
	;;
esac

##############################################################################
# Building section
# You probably don't have to touch anything after this
##############################################################################

##############################################################################
# Helper function definitions
##############################################################################

# Fetch a versioned file from a URL
function fetch {
    if [ ! -e ${STAMPS}/$1.fetch ]; then
        if [ ! -e ${SOURCES}/$1 ]; then
            log "Downloading $1 sources..."
			if [ "x$3" != "x" ]; then
				wget -c ${FETCH_NO_PASSIVE} ${FETCH_NO_CERTCHECK} -O $3 $2 && touch ${STAMPS}/$1.fetch
			else
				wget -c ${FETCH_NO_PASSIVE} ${FETCH_NO_CERTCHECK} $2 && touch ${STAMPS}/$1.fetch
			fi
        fi
    fi
}

function clone {
    local NAME=$1
    local GIT_REF=$2
    local GIT_URL=$3
    local POST_CLONE=$4
    local GIT_SHA=$(git ls-remote ${GIT_URL} ${GIT_REF} | cut -f 1)

    # It seems that the ref is actually a SHA as it could not be found through ls-remote
    if [ "x${GIT_SHA}" == "x" ]; then
        local GIT_SHA=${GIT_REF}
    fi

    # Setting uppercase NAME variable for future use to the source file name
    eval $(echo ${NAME} | tr "[:lower:]" "[:upper:]")=${NAME}-${GIT_SHA}

    # Clone the repository and do all necessary operations until we get an archive
    if [ ! -e ${STAMPS}/${NAME}-${GIT_SHA}.fetch ]; then
        # Making sure there is nothing in our way
        if [ -e ${NAME}-${GIT_SHA} ]; then
            log "The clone directory ${NAME}-${GIT_SHA} already exists, removing..."
            rm -rf ${NAME}-${GIT_SHA}
        fi
        log "Cloning ${NAME}-${GIT_SHA} ..."
        git clone --recursive ${GIT_URL} ${NAME}-${GIT_SHA}
        cd ${NAME}-${GIT_SHA}
        log "Checking out the revision ${GIT_REF} with the SHA ${GIT_SHA} ..."
        git checkout -b sft-branch ${GIT_SHA}
	if [ "x${POST_CLONE}" != "x" ]; then
		log "Running post clone code for ${NAME}-${GIT_SHA} ..."
		${POST_CLONE}
	fi
        log "Removing .git directory from ${NAME}-${GIT_SHA} ..."
        rm -rf .git
        cd ..
        log "Generating source archive for ${NAME}-${GIT_SHA} ..."
        tar cfj ${SOURCES}/${NAME}-${GIT_SHA}.tar.bz2 ${NAME}-${GIT_SHA}
        rm -rf ${NAME}-${GIT_SHA}
        touch ${STAMPS}/${NAME}-${GIT_SHA}.fetch
    fi
}

# Log a message out to the console
function log {
    echo "******************************************************************"
    echo "* $*"
    echo "******************************************************************"
}

# Unpack an archive
function unpack {
    log Unpacking $*
    # Use 'auto' mode decompression.  Replace with a switch if tar doesn't support -a
    ARCHIVE=$(ls ${SOURCES}/$1.tar.*)
    case ${ARCHIVE} in
	*.bz2)
	    echo "archive type bz2"
	    TYPE=j
	    ;;
	*.gz)
	    echo "archive type gz"
	    TYPE=z
	    ;;
	*)
	    echo "Unknown archive type of $1"
	    echo ${ARCHIVE}
	    exit 1
	    ;;
    esac
    ${TAR} xf${TYPE}${TARFLAGS} ${SOURCES}/$1.tar.*
}

# Install a build
function install {
    log $1
    ${SUDO} make ${MAKEFLAGS} $2 $3 $4 $5 $6 $7 $8
}

##############################################################################
# Create directories
##############################################################################

mkdir -p ${STAMPS} ${SOURCES}

cd ${SOURCES}

##############################################################################
# Fetch sources
##############################################################################

if [ ${ICESTORM_EN} != 0 ]; then
	if [ "x${ICESTORM_GIT}" == "x" ]; then
		log "There is no icestorm stable release download server yet!"
		exit 1
		#fetch ${ICESTORM} https://github.com/cliffordwolf/icestorm/archive/${ICESTORM}.tar.bz2
	else
		clone icestorm ${ICESTORM_GIT} git://github.com/cliffordwolf/icestorm.git
	fi
fi

if [ ${PRJTRELLIS_EN} != 0 ]; then
	if [ "x${PRJTRELLIS_GIT}" == "x" ]; then
		log "There is no prjtrellis stable release download server yet!"
		exit 1
		#fetch ${PRJTRELLIS} https://github.com/SymbiFlow/prjtrellis/archive/${PRJTRELLIS}.tar.bz2
	else
		clone prjtrellis ${PRJTRELLIS_GIT} git://github.com/SymbiFlow/prjtrellis.git
	fi
fi

if [ ${ARACHNEPNR_EN} != 0 ]; then
	if [ "x${ARACHNEPNR_GIT}" == "x" ]; then
		log "There is no arachne-pnr stable release download server yet!"
		exit 1
		#fetch ${ARACHNEPNR} https://github.com/YosysHQ/arachne-pnr/archive/${ARACHNEPNR}.tar.bz2
	else
		clone arachnepnr ${ARACHNEPNR_GIT} git://github.com/YosysHQ/arachne-pnr.git
	fi
fi

if [ ${NEXTPNR_ICE40_EN} != 0 ] || [ ${NEXTPNR_ECP5_EN} != 0 ]; then
	if [ "x${NEXTPNR_GIT}" == "x" ]; then
		log "There is no nextpnr stable release download server yet!"
		exit 1
		#fetch ${NEXTPNR} https://github.com/YosysHQ/nextpnr/archive/${NEXTPNR}.tar.bz2
	else
		clone nextpnr ${NEXTPNR_GIT} git://github.com/YosysHQ/nextpnr.git
	fi
fi

if [ ${YOSYS_EN} != 0 ]; then
	if [ "x${YOSYS_GIT}" == "x" ]; then
		fetch ${YOSYS} https://github.com/YosysHQ/yosys/archive/${YOSYS}.tar.gz
	else
		clone yosys ${YOSYS_GIT} git://github.com/YosysHQ/yosys.git
	fi
fi

if [ ${IVERILOG_EN} != 0 ]; then
	if [ "x${IVERILOG_GIT}" == "x" ]; then
		fetch ${IVERILOG} https://github.com/steveicarus/iverilog/archive/${IVERILOG_VERSION}.tar.gz ${IVERILOG}.tar.gz
	else
		clone iverilog ${IVERILOG_GIT} git://github.com/steveicarus/iverilog.git
	fi
fi

##############################################################################
# Build tools
##############################################################################

cd ${SUMMON_DIR}

if [ ! -e build ]; then
    mkdir build
fi

if [ ${ICESTORM_EN} != 0 ]; then
if [ ! -e ${STAMPS}/${ICESTORM}.build ]; then
    unpack ${ICESTORM}
    cd ${ICESTORM}
    log "Building ${ICESTORM}"
    make ${MAKEFLAGS} PREFIX=${PREFIX}
    install ${ICESTORM} PREFIX=${PREFIX} install
    cd ..
    log "Cleaning up ${ICESTORM}"
    touch ${STAMPS}/${ICESTORM}.build
    rm -rf ${ICESTORM}
fi
fi

if [ ${PRJTRELLIS_EN} != 0 ]; then
if [ ! -e ${STAMPS}/${PRJTRELLIS}.build ]; then
    unpack ${PRJTRELLIS}
    cd ${PRJTRELLIS}/libtrellis
    log "Configuring ${PRJTRELLIS}"
    cmake -DCMAKE_INSTALL_PREFIX=${PREFIX} .
    log "Building ${PRJTRELLIS}"
    make ${MAKEFLAGS}
    install ${PRJTRELLIS} install
    cd ../..
    log "Running post install tasks for ${PRJTRELLIS}"
    cd ${PREFIX}/share/trellis
    ln -sf ../../lib/trellis libtrellis
    cd -
    log "Cleaning up ${PRJTRELLIS}"
    touch ${STAMPS}/${PRJTRELLIS}.build
    rm -rf build/* ${PRJTRELLIS}
fi
fi

if [ ${ARACHNEPNR_EN} != 0 ]; then
if [ ! -e ${STAMPS}/${ARACHNEPNR}.build ]; then
    unpack ${ARACHNEPNR}
    cd ${ARACHNEPNR}
    log "Building ${ARACHNEPNR}"
    make ${MAKEFLAGS} PREFIX=${PREFIX}
    install ${ARACHNEPNR} PREFIX=${PREFIX} install
    cd ..
    log "Cleaning up ${ARACHNEPNR}"
    touch ${STAMPS}/${ARACHNEPNR}.build
    rm -rf ${ARACHNEPNR}
fi
fi

if [ ${NEXTPNR_ICE40_EN} != 0 ] || [ ${NEXTPNR_ECP5_EN} != 0 ]; then
if [ ! -e ${STAMPS}/${NEXTPNR}.build ]; then
    unpack ${NEXTPNR}
    cd build
    log "Configuring ${NEXTPNR}"
    CMAKE_PREFIX_PATH=${QT5_PREFIX:-${QT5_PREFIX}/lib/cmake/Qt5}
    if [ ${NEXTPNR_ICE40_EN} != 0 ]; then
      NEXTPNR_ARCH="ice40;"
    fi
    if [ ${NEXTPNR_ECP5_EN} != 0 ]; then
      NEXTPNR_ARCH="${NEXTPNR_ARCH}ecp5"
    fi
    cmake -DARCH="${NEXTPNR_ARCH}" -DCMAKE_INSTALL_PREFIX=${PREFIX} \
        -DCMAKE_PREFIX_PATH=${CMAKE_PREFIX_PATH} \
        -DBUILD_GUI=${NEXTPNR_BUILD_GUI} \
        -DTRELLIS_ROOT=${PREFIX}/share/trellis \
        -DICEBOX_ROOT=${PREFIX}/share/icebox ../${NEXTPNR}
    log "Building ${NEXTPNR}"
    make ${MAKEFLAGS}
    install ${NEXTPNR} install
    cd ..
    log "Cleaning up ${NEXTPNR}"
    touch ${STAMPS}/${NEXTPNR}.build
    rm -rf build/* ${NEXTPNR}
fi
fi

if [ ${YOSYS_EN} != 0 ]; then
if [ ! -e ${STAMPS}/${YOSYS}.build ]; then
    unpack ${YOSYS}
    if [ "x${YOSYS_GIT}" == "x" ]; then
        cd yosys-${YOSYS}
    else
        cd ${YOSYS}
    fi
    log "Building ${YOSYS}"
    make ${MAKEFLAGS} ${YOSYSFLAGS} PREFIX=${PREFIX}
    install ${YOSYS} PREFIX=${PREFIX} install
    cd ..
    log "Cleaning up ${YOSYS}"
    touch ${STAMPS}/${YOSYS}.build
    if [ "x${YOSYS_GIT}" == "x" ]; then
        rm -rf yosys-${YOSYS}
    else
        rm -rf ${YOSYS}
    fi
fi
fi

if [ ${IVERILOG_EN} != 0 ]; then
if [ ! -e ${STAMPS}/${IVERILOG}.build ]; then
    unpack ${IVERILOG}
    cd ${IVERILOG}
    log "Running autogen for ${IVERILOG}"
    sh ./autoconf.sh
    cd ../build
    log "Configuring ${IVERILOG}"
    ../${IVERILOG}/configure --prefix=${PREFIX}
    log "Building ${IVERILOG}"
    make ${MAKEFLAGS}
    install ${IVERILOG} install
    cd ..
    log "Cleaning up ${IVERILOG}"
    touch ${STAMPS}/${IVERILOG}.build
    rm -rf build/* ${IVERILOG}
fi
fi

