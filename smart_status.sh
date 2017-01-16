#!/bin/bash

function trim()
{
    echo -e "$1" | sed -e 's/[[:space:]]*$//'
}

if [[ $(whoami) != "root" ]]; then
    echo -e "run as root"
    exit 1
fi

SMARTCTL=$(which smartctl)
OLD_IFS=$IFS
IFS=$'\n'
total=0

for line in $($SMARTCTL --scan)
do
    total=$(($total+1))
done

for line in $($SMARTCTL --scan)
do
    total=$(($total-1))
    IFS='#' read -r -a device_info <<< "$line"
    SMART_DEVICE_NAME=$(trim "${device_info[0]}")
    SMART_DEVICE_SHORT_NAME=$(echo $SMART_DEVICE_NAME | cut -d " " -f 1)
    IFS=$OLD_IFS
    SMART_STATUS=$($SMARTCTL -H ${SMART_DEVICE_NAME} | grep -i health | grep -E 'OK|PASSED')

    if [ $? -eq 0 ]; then
	echo $SMART_DEVICE_NAME OK
    else
	echo $SMART_DEVICE_NAME FAIL
    fi
done
