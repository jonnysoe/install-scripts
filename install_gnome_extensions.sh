#!/bin/bash
function install_apt_dependencies() {
    local apt_list=()
    if ! command -v jq > /dev/null; then
        apt_list+=(jq)
    fi

    # GNOME Shell Integration for Chrome
    if command -v google-chrome > /dev/null; then
        if ! command -v chrome-gnome-shell > /dev/null; then
            apt_list+=(chrome-gnome-shell)
        fi
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

    # Link (file) format for GNOME extensions is fixed
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
    local first=$2

    # Default to test first version to v12
    first=${first:=12}

    # Check version compatibility
    # raw
    local shellr=`gnome-shell --version`
    # remove "GNOME Shell " to get the version x.y.z
    local shellv=${shellr/#"GNOME Shell "}
    # short versions x.y and x respectively
    local shellsv=${shellv%.*}
    local shellmajor=${shellsv%.*}
    if [ ${shellmajor} -le 3 ]; then
        # Mirror major and major.minor version so that it will not be used for detection
        # GNOME 4 and above no longer use semver 4.y.z like the GNOME 3 and below
        shellmajor=${shellsv}
    fi

    # `gnome-extensions list` seems to occasionally stop script abruptly??
    if [[ ! -d ~/.local/share/gnome-shell/extensions/${ext_uuid} ]] || [[ ! -d /usr/share/gnome-shell/extensions/${ext_uuid} ]]; then
        # @todo test version bug here if first tested version is not compatible, it will break loop and install first version
        local test=${first}
        local latest=${first}
        while [[ true ]]; do
            echo "Testing ${ext_uuid} - version ${test}"
            download_ext ${ext_uuid} ${test}

            if [[ ! -d ${test} ]]; then
                # Testing version is invalid
                break
            fi

            # Test version compatibility
            local compats=`cat ./${test}/${ext_uuid}/metadata.json | jq '."shell-version"'`
            echo ${compats} | grep -e ${shellsv} -e ${shellmajor} || break
            echo "${ext_uuid} - version ${test} is compatible with GNOME ${shellv}"

            # Update latest found version
            latest=${test}
            test=$((${latest} + 1))
        done

        echo "Installing ${ext_uuid} version ${latest} . . ."

        # @todo make this configurable to either install system-wide or current user
        # Do not use mv as it will retain user specific access in system directory
        sudo cp -r ${latest}/${ext_uuid} /usr/share/gnome-shell/extensions/
        sudo chmod a+x /usr/share/gnome-shell/extensions/${ext_uuid}/extension.js
        sudo chmod a+r /usr/share/gnome-shell/extensions/${ext_uuid}/metadata.json

        # Remove test directories
        dirs=(`seq ${first} ${test}`)
        for dir in ${dirs[@]}; do
            rm -rf ${dir}
        done

        # Add new extension to reload list
        extensions+=(${ext_uuid})

        # @todo fix wayland
        # https://www.reddit.com/r/gnome/comments/eb4pn9/comment/fb3ypc7/?utm_source=share&utm_medium=web3x&utm_name=web3xcss&utm_term=1&utm_content=share_button
    fi
}

if command -v gnome-shell > /dev/null; then
    if command -v apt > /dev/null; then
        install_apt_dependencies
    fi

    extensions=()

    # Extension repo: https://github.com/bdaase/noannoyance.git
    # Download proper version from: https://extensions.gnome.org/extension/2182/noannoyance/
    install_extension noannoyance@daase.net 12

    # Configure only for Ubuntu
    if [[ -n "`grep ID=ubuntu /etc/os-release`" ]]; then
        # Extension repo: https://github.com/home-sweet-gnome/dash-to-panel.git
        # Download proper version from: https://extensions.gnome.org/extension/1160/dash-to-panel/
        install_extension dash-to-panel@jderose9.github.com 42

        # Extension repo: https://gitlab.com/arcmenu/ArcMenu
        # Download proper version from: https://extensions.gnome.org/extension/3628/arcmenu/
        install_extension arcmenu@arcmenu.com 13
    fi

    # Enable new extensions
    if [ ${#extensions} -gt 0 ]; then
        # Reload gnome-shell to reload gnome-extensions for new extensions to show up to enable/disable
        pkill gnome-shell

        for extension in ${extensions[@]}; do
            echo "Enabling ${extension} . . ."
            gnome-extensions enable ${extension}
        done

        echo "Configuring extensions . . ."

        ext_uuid=dash-to-panel@jderose9.github.com
        if [[ ! -d ~/.local/share/gnome-shell/extensions/${ext_uuid} ]] || [[ ! -d /usr/share/gnome-shell/extensions/${ext_uuid} ]]; then
            echo "Configuring dash-to-panel . . ."
            # There is a bug in dash-to-panel for not registering itself for `gsettings set` to configure
            # https://github.com/home-sweet-gnome/dash-to-panel/issues/394#issuecomment-386922149
            # Use primitive `dconf read` and `dconf write`, learn extension prefs changes with `dconf watch /`
            # https://askubuntu.com/a/1178587

            key=/org/gnome/shell/extensions/dash-to-panel/appicon-margin
            value=4
            dconf write ${key} ${value}

            ext_uuid=arcmenu@arcmenu.com
            if [[ ! -d ~/.local/share/gnome-shell/extensions/${ext_uuid} ]] || [[ ! -d /usr/share/gnome-shell/extensions/${ext_uuid} ]]; then
                # Disable showAppsButton on dash-to-panel
                # Swap systemMenu and dataMenu position

                key=/org/gnome/shell/extensions/dash-to-panel/panel-element-positions
                # @todo Replacing them programmatically is ideal but they don't appear fresh off installation
                # value=`dconf read ${key} | sed 's@"showAppsButton","visible":true@"showAppsButton","visible":false@' | sed 's@systemMenu@dateMenu' | sed 's@dateMenu@systemMenu'`
                value='{"0":[{"element":"showAppsButton","visible":false,"position":"stackedTL"},{"element":"activitiesButton","visible":false,"position":"stackedTL"},{"element":"leftBox","visible":true,"position":"stackedTL"},{"element":"taskbar","visible":true,"position":"stackedTL"},{"element":"centerBox","visible":true,"position":"stackedBR"},{"element":"rightBox","visible":true,"position":"stackedBR"},{"element":"systemMenu","visible":true,"position":"stackedBR"},{"element":"dateMenu","visible":true,"position":"stackedBR"},{"element":"desktopButton","visible":true,"position":"stackedBR"}]}'
                value="'${value}'"
                dconf write ${key} ${value}

                key=/org/gnome/shell/extensions/arcmenu/menu-hotkey
                value="'Super_L'"
                dconf write ${key} ${value}

                key=/org/gnome/shell/extensions/arcmenu/override-menu-button-hover-background-color
                value=true
                dconf write ${key} ${value}

                key=/org/gnome/shell/extensions/arcmenu/override-menu-button-active-background-color
                value=true
                dconf write ${key} ${value}
            fi
        fi
    fi
fi
