#!/bin/bash
function install_apt_dependencies() {
    local apt_list=()
    if ! command -v jq > /dev/null; then
        apt_list+=(jq)
    fi

    if ! command -v chrome-gnome-shell > /dev/null; then
        apt_list+=(chrome-gnome-shell)
    fi

    if [[ -n "${apt_list}" ]]; then
        sudo apt install -y ${apt_list[@]}
    fi
}

function download_ext() {
    local uuid=$1
    local ver=$2

    # Remove @
    uuid=${uuid//@}

    local file=${uuid}.v${ver}.shell-extension.zip
    local link=https://extensions.gnome.org/extension-data/${file}

    if [[ ! -f ${file} ]]; then
        if wget --spider -q ${link}; then
            wget ${link}
        fi
    fi
    if [[ -f ${file} ]]; then
        mkdir -p ${ver}
        unzip -o ${file} -d ${ver}/${ext_uuid}
    fi
}

function install_extension() {
    local ext_uuid=$1

    # Check version compatibility
    # raw
    local shellr=`gnome-shell --version`
    # remove "GNOME Shell " to get the version
    local shellv=${shellr/#"GNOME Shell "}
    # short versions
    local shellsv=${shellv%.*}
    local shellssv=${shellsv%.*}

    local first=12
    if [[ ! -d ~/.local/share/gnome-shell/extensions/${ext_uuid} ]] || [[ ! -d /usr/share/gnome-shell/extensions/${ext_uuid} ]]; then
        local test=${first}
        local latest=${first}
        while [[ true ]]; do
            echo "Testing version ${test}"
            download_ext ${ext_uuid} ${test}

            if [[ ! -d ${test} ]]; then
                # Testing version is invalid
                break
            fi

            # Test version compatibility
            local compats=`cat ./${test}/${ext_uuid}/metadata.json | jq '."shell-version"'`
            echo ${compats} | grep -e ${shellsv} -e ${shellssv} || break

            # Update latest found version
            latest=${test}
            test=$((${latest} + 1))
        done

        echo "Installing ${ext_uuid} version ${latest} . . ."

        # Do not use mv as it will retain user specific access in system directory
        sudo cp -r ${latest}/${ext_uuid} /usr/share/gnome-shell/extensions/
        sudo chmod a+x /usr/share/gnome-shell/extensions/${ext_uuid}/extension.js
        sudo chmod a+r /usr/share/gnome-shell/extensions/${ext_uuid}/metadata.json

        # Remove test directories
        dirs=(`seq ${first} ${test}`)
        for dir in ${dirs[@]}; do
            rm -rf ${dir}
        done

        # Reload gnome-shell to reload gnome-extensions to enable new extension
        pkill gnome-shell
        gnome-extensions enable ${ext_uuid}

        # @todo fix wayland
        # https://www.reddit.com/r/gnome/comments/eb4pn9/comment/fb3ypc7/?utm_source=share&utm_medium=web3x&utm_name=web3xcss&utm_term=1&utm_content=share_button
    fi
}

if command -v apt > /dev/null; then
    install_apt_dependencies
fi

if command -v gnome-shell > /dev/null; then
    # Extension repo: https://github.com/bdaase/noannoyance.git
    # Download proper version from: https://extensions.gnome.org/extension/2182/noannoyance/
    install_extension noannoyance@daase.net
fi
