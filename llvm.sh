#!/bin/bash
################################################################################
# Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
# See https://llvm.org/LICENSE.txt for license information.
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
################################################################################
#
# This script will install the llvm toolchain on the different
# Debian and Ubuntu versions
# This was modified from: https://apt.llvm.org/llvm.sh

# Get value from a combined argument and value
function get_attached_val() {
    local ARG=$1
    local PAT=${2/--/-}
    PAT=${PAT/-/}           # remove '-' from "full argument" pattern
    local SHORT=${PAT:0:1}  # "short argument" pattern
    ARG=${ARG/--/-}
    local ARG_VAL=${ARG/-${PAT}/-${SHORT}}  # trim pattern to single char
    local VAL=${ARG_VAL#*-${SHORT}=}        # remove arg (including =)
    VAL=${VAL#*-${SHORT}}                   # remove arg
    echo $VAL
}

function parse_args() {
    # https://stackoverflow.com/questions/192249/how-do-i-parse-command-line-arguments-in-bash/14203146#14203146
    POSITIONAL_ARGS=()

    while [[ $# -gt 0 ]]; do
        # Internally treat arguments with only a single dash '-'
        local ARG=${1/--/-}
        case $ARG in
            -v*)
                local VAL=`get_attached_val $ARG version`
                if [[ -z "$VAL" ]]; then
                    VAL="$2"
                    shift # past argument
                fi
                if [[ $VAL =~ [^[:digit:]] ]]; then
                    # Not digit or anything, don't know what to do
                    echo "Invalid version $VAL"
                    exit 1
                fi
                LLVM_VERSION=$ARG
                shift # past value
                ;;
            -a*)
                local VAL=`get_attached_val $ARG all`
                if [[ -n "$VAL" ]]; then
                    # Nothing should be attached behind "all"
                    echo "Unknown option $1"
                    exit 1
                fi
                ALL=1
                shift # past value
                ;;
            -*)
                # Not digit or anything, don't know what to do
                echo "Unknown option $1"
                exit 1
                ;;
            *)
                POSITIONAL_ARGS+=("$1") # save positional arg
                shift # past argument
                ;;
        esac
    done

    for ARG in ${POSITIONAL_ARGS[@]}; do
        case ${ARG,,} in
            all)
                ALL=1
                ;;
            *)
                if [[ $ARG =~ [^[:digit:]] ]]; then
                    # Not digit or anything, don't know what to do
                    echo "Unknown option $ARG"
                    exit 1
                fi
                LLVM_VERSION=$ARG
                ;;
        esac
    done
}

CURRENT_LLVM_STABLE=14

# We default to the current stable branch of LLVM
LLVM_VERSION=$CURRENT_LLVM_STABLE
ALL=0

# read optional command line argument
parse_args $@

if [[ $EUID -eq 0 ]]; then
   echo "This script must NOT be run as root!"
   exit 1
fi

declare -A LLVM_VERSION_PATTERNS
LLVM_VERSION_PATTERNS[9]="-9"
LLVM_VERSION_PATTERNS[10]="-10"
LLVM_VERSION_PATTERNS[11]="-11"
LLVM_VERSION_PATTERNS[12]="-12"
LLVM_VERSION_PATTERNS[13]="-13"
LLVM_VERSION_PATTERNS[14]="-14"
LLVM_VERSION_PATTERNS[15]=""

if [ ! ${LLVM_VERSION_PATTERNS[$LLVM_VERSION]+_} ]; then
    echo "This script does not support LLVM version $LLVM_VERSION"
    exit 3
fi

LLVM_VERSION_STRING=${LLVM_VERSION_PATTERNS[$LLVM_VERSION]}

DISTRO=`lsb_release -is`
VERSION=`lsb_release -sr`

source /etc/os-release
DISTRO=${DISTRO,,}
case $DISTRO in
    debian)
        if [[ "$VERSION" == "unstable" ]] || [[ "$VERSION" == "testing" ]]; then
            CODENAME=unstable
            LINKNAME=
        else
            CODENAME=$VERSION_CODENAME
            LINKNAME=-$CODENAME
        fi
        ;;
    *)
        if [[ -n "$UBUNTU_CODENAME" ]]; then
            CODENAME=$UBUNTU_CODENAME
            if [[ -n "$CODENAME" ]]; then
                LINKNAME=-$CODENAME
            fi
        fi
        ;;
esac

if [[ -n "$CODENAME" ]]; then
    REPO_NAME="deb http://apt.llvm.org/${CODENAME}/  llvm-toolchain${LINKNAME}${LLVM_VERSION_STRING} main"
    
    if ! command -v curl &> /dev/null; then
        sudo apt install -y curl
    fi

    if ! curl --head --silent --fail http://apt.llvm.org/${CODENAME} &> /dev/null; then
        echo "Distribution '$DISTRO' in version '$VERSION' is not supported by this script (${DIST_VERSION})."
        exit 2
    fi
fi

# install everything
if [[ -z "`apt-key list | grep -i llvm`" ]]; then
    wget -qO - https://apt.llvm.org/llvm-snapshot.gpg.key | sudo apt-key add -
fi
sudo add-apt-repository -y "${REPO_NAME}"
apt-get update
PKG="clang-$LLVM_VERSION lldb-$LLVM_VERSION lld-$LLVM_VERSION clangd-$LLVM_VERSION"
if [[ $ALL -eq 1 ]]; then
    # same as in test-install.sh
    # No worries if we have dups
    PKG="$PKG clang-tidy-$LLVM_VERSION clang-format-$LLVM_VERSION clang-tools-$LLVM_VERSION llvm-$LLVM_VERSION-dev lld-$LLVM_VERSION lldb-$LLVM_VERSION llvm-$LLVM_VERSION-tools libomp-$LLVM_VERSION-dev libc++-$LLVM_VERSION-dev libc++abi-$LLVM_VERSION-dev libclang-common-$LLVM_VERSION-dev libclang-$LLVM_VERSION-dev libclang-cpp$LLVM_VERSION-dev libunwind-$LLVM_VERSION-dev"
fi
sudo apt install -y $PKG

# Add symbolic link(s)
if [[ -f /usr/lib/llvm-$LLVM_VERSION/bin/clang-format ]]; then
    if [[ ! -f /usr/bin/clang-format ]]; then
        # Add clang-format to be executable globally
        # NOTE: this will NOT replace clang-format that was installed from APT
        sudo ln -s /usr/lib/llvm-$LLVM_VERSION/bin/clang-format /usr/bin/clang-format
    fi
fi
