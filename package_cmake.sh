#!/bin/bash

function package_debian() {
    local url="https://github.com/Kitware/CMake/releases/download/v3.30.5/cmake-3.30.5-linux-x86_64.sh"
    local script=`ls cmake-*.sh`
    local ori_script=${script}

    if [[ -z "${script}" ]]; then
        # No cmake script!
        script=`basename ${url}`
        wget -O ${script} ${url}
    fi
    if [[ -z "${script}" ]]; then
        echo "No cmake install script and failed to download default install script!"
        return 1
    fi

    local package=${script%.*}

    # Split string into array
    # https://stackoverflow.com/a/5257398/19336104
    local decoded=(${package//-/ })
    local name=${decoded[0]}
    local version=${decoded[1]}
    local os=${decoded[2]}
    local arch=`dpkg --print-architecture`

    if [[ "${arch}" != "amd64" ]]; then
        echo "CMake only supports amd64 CPU architecture!"
        return 2
    fi

    # Change package name to resemble a deb package
    package=${name}_${version}_${arch}

    # Prepare file hierarchy in package
    mkdir -p ${package}/usr
    bash ./${script} --prefix=${package}/usr/ --skip-license

    # Get Installed-Size
    local usage=(`du -d 0 ${package}`)

    # Create deb package control file
    # https://www.debian.org/doc/debian-policy/ch-controlfields.html
    mkdir -p ${package}/DEBIAN
    echo "Package: ${name}" > ${package}/DEBIAN/control
    echo "Version: ${version}" >> ${package}/DEBIAN/control
    echo "License: see https://cmake.org/licensing/" >> ${package}/DEBIAN/control
    echo "Architecture: ${arch}" >> ${package}/DEBIAN/control
    echo "Essential: no" >> ${package}/DEBIAN/control
    echo "Priority: optional" >> ${package}/DEBIAN/control
    echo "Maintainer: Unofficial" >> ${package}/DEBIAN/control
    echo "Homepage: https://cmake.org/download/" >> ${package}/DEBIAN/control
    echo "Installed-size: ${usage[0]}" >> ${package}/DEBIAN/control

    # Provides as a virtual package name to prevent user from installing cmake-curses-gui and cmake-qt-gui doesn't really work
    # it can only help with satisfying dependency, but leaving them here to prevent conflicts
    # @todo check if `Provides: cmake-data` with `Depends: dh-elpa-helper` can help to prevent removal
    # Package relationships:
    # cmake - cmake, ctest, cpack
    # cmake-curses-gui (Depends: cmake-data, dh-elpa-helper) - ccmake
    # cmake-qt-gui (Depends: cmake-data, dh-elpa-helper, libqtX, etc.) - cmake-gui
    # NOTE: only cmake-data have conflicts; dh-elpa-helper along with libqtX, etc. was statically linked
    echo "Provides: cmake-qt-gui" >> ${package}/DEBIAN/control
    echo "Conflicts: cmake, cmake-data, cmake-curses-gui, cmake-qt-gui" >> ${package}/DEBIAN/control
    echo "Replaces: cmake, cmake-data, cmake-curses-gui, cmake-qt-gui" >> ${package}/DEBIAN/control
    echo "Breaks: cmake, cmake-data, cmake-curses-gui, cmake-qt-gui" >> ${package}/DEBIAN/control

    echo "Description: Cross-Platform Makefile Generator" >> ${package}/DEBIAN/control
    # https://cmake.org/about/
    echo " CMake is an open source, cross-platform family of tools designed to build," >> ${package}/DEBIAN/control
    echo " test, and package software. CMake gives you control of the software" >> ${package}/DEBIAN/control
    echo " compilation process using simple independent configuration files. Unlike" >> ${package}/DEBIAN/control
    echo " many cross-platform systems, CMake is designed to be used in conjunction" >> ${package}/DEBIAN/control
    echo " with the native build environment." >> ${package}/DEBIAN/control

    # Using preinst to teach user how to remove conflicting packages
    # dpkg couldn't use Conflicts for cmake due the package name being VERSION_CODENAME specific, eg:
    # - cmake/focal-updates,now 3.16.3-1ubuntu1.20.04.1 amd64
    # - cmake/jammy-updates 3.22.1-1ubuntu1.22.04.2 amd64
    # The Conflicts list will be exhaustive to add:
    # - <= 3.16.3-1ubuntu1.20.04.1
    # - <= 3.22.1-1ubuntu1.22.04.2
    cat << 'EOF' > ${package}/DEBIAN/preinst
#!/bin/bash
# `source /etc/os-reelase` cannot be used in preinst due to the lack of `source` command
VERSION_CODENAME=`cat /etc/os-release | grep VERSION_CODENAME`

# Strip `=` and anything before
VERSION_CODENAME=${VERSION_CODENAME##*=}

# Prepare conflicting packages
arch=`dpkg --print-architecture`
conflicts=()
if [[ -n "`apt list 2> /dev/null | grep ^cmake/${VERSION_CODENAME} | grep ${arch} | grep installed`" ]]; then
    conflicts+=(cmake)
fi
if [[ -n "`apt list 2> /dev/null | grep ^cmake-data/${VERSION_CODENAME} | grep ${arch} | grep installed`" ]]; then
    conflicts+=(cmake-data)
fi
if [[ -n "`apt list 2> /dev/null | grep ^cmake-curses-gui/${VERSION_CODENAME} | grep ${arch} | grep installed`" ]]; then
    conflicts+=(cmake-curses-gui)
fi
if [[ -n "`apt list 2> /dev/null | grep ^cmake-qt-gui/${VERSION_CODENAME} | grep ${arch} | grep installed`" ]]; then
    conflicts+=(cmake-qt-gui)
fi

if [[ ${#conflicts[@]} -gt 0 ]]; then
    echo "There are conflicting packages on the system, run the following commands before reinstalling:"
    echo "	sudo apt purge -y ${conflicts[@]}"
    echo "	sudo apt autoremove -y"

    exit 1
fi
EOF

    chmod a+x ${package}/DEBIAN/preinst

    # Package the whole directory
    dpkg-deb --build --root-owner-group ${package}

    # Cleanup
    if [[ "${ori_script}" != "${script}" ]]; then
        rm -f ${script}
    fi
    rm -rf ${package}

    return 0
}

# S{BASH_SOURCE[0]} - is valid when script was called with `source`
# S{0} - is valid when script was executed normally, eg. `.`, `bash`
SCRIPT_SOURCE=${BASH_SOURCE[0]:?${0}}
SCRIPT_PATH=`realpath ${SCRIPT_SOURCE}`
SCRIPT_DIR=`dirname ${SCRIPT_PATH}`
pushd ${SCRIPT_DIR} > /dev/null

ERROR_CODE=0

# https://askubuntu.com/questions/41332/how-do-i-check-if-i-have-a-32-bit-or-a-64-bit-os/447306#447306
case `uname` in
    Linux)
        source /etc/os-release
        DISTRO_ID="${ID} ${ID_LIKE}"
        if [[ -n "`echo ${DISTRO_ID} | grep -e ubuntu -e debian`" ]]; then
            package_debian
            ERROR_CODE=$?
        fi
        ;;
    *)
        # Not supported yet
        echo "${SCRIPT_SOURCE} is not supported in the current OS!"
        ERROR_CODE=3
esac

popd > /dev/null
exit $ERROR_CODE