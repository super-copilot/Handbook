#!/bin/bash
#!/usr/bin/env bash

dirname=$(cd `dirname $0` && echo `pwd`)
disk="$1"
disk_num=`fdisk -l | awk '$1=="Disk"&&$2~"^/dev"&&$2!~"^/dev/sda" {split($2,s,":"); print s[1]}'`

# Check System
[[ $EUID -ne 0 ]] && echo "Error: This script must be run as root" && exit 1
# [[ -f /etc/redhat-release ]] && os='centos'
# [[ ! -z "`egrep -i debian /etc/issue`"]] && os='debian'
# [[ ! -z "`egrep -i ubuntu /etc/issue`"]] && os='ubuntu'
# [[ "$os" == '' ]] && echo "Error: Your system is not supported to run it!" && exit 1

function help() {
    echo "Usage: help"
}


function check_parameters() {
    if [[ -z $disk ]]; then
        echo "Error: Please add parameters before executing this script"
        echo 'If you need help, please add "--help" to view the help detail line'
    elif [[ -n "--help" ]]; then
        help
    fi
}


function init_disk() {
    for i in $disk_num
    do
      parted  -s $i mklabel gpt
      parted  -s $i mkpart primary 1 100%
      mkfs.xfs -f ${i}1
    done
}

parted /dev/sdb <<EOF
mklabel
gpt
mkpart
primary
ext4
1
100G
quit
EOF
