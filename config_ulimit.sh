#!/usr/bin/bash

# Algorithm for Lifting ulimit
# https://askubuntu.com/a/162230
nofile=4096

# cap nofile to hard nofile
hnofile=`ulimit -Hn`
nofile=$((${nofile} > ${hnofile} ? ${hnofile} : ${nofile}))

# cap nofile to file-max
filemax=`cat /proc/sys/fs/file-max`
nofile=$((${nofile} > ${filemax} ? ${filemax} : ${nofile}))

# Configuration for headless and SSH session ulimits
script=/etc/security/limits.conf
if [[ -z "`cat ${script} | grep nofile | grep soft`" ]] || [[ -n "`cat ${script} | grep nofile | grep soft | grep \#`" ]]; then
    # @todo update this to check against the current `* soft nofile limit``
    echo "- ${script}: adding soft nofile for all users"
    sudo sh -c "echo \"*	soft	nofile	${nofile}\" >> ${script}"
fi

# Don't seem necessary in Ubuntu 20.04 and derivatives, but keep it around for now
scripts=(`ls /etc/pam.d/common-session*`)
for script in ${scripts[@]}; do
    if [[ -z "`cat ${script} | grep pam_limits`" ]] || [[ -n "`cat ${script} | grep pam_limits | grep \#`" ]]; then
        echo "- ${script}: adding pam_limits.so"
        sudo sh -c "echo \"session	required	pam_limits.so\" >> ${script}"
    fi
done

# Additional configuration for GUI session (on top of systemd)
# https://superuser.com/a/1200818
if [[ -n "`readlink /sbin/init | grep systemd`" ]]; then
    scripts=(/etc/systemd/user.conf /etc/systemd/system.conf)
    for script in ${scripts[@]}; do
        if [[ -z "`cat ${script} | grep DefaultLimitNOFILE`" ]] || [[ -n "`cat ${script} | grep DefaultLimitNOFILE | grep \#`" ]]; then
            echo "- ${script}: adding DefaultLimitNOFILE"
            sudo sh -c "echo \"DefaultLimitNOFILE=${nofile}\" >> ${script}"
        fi
    done
fi