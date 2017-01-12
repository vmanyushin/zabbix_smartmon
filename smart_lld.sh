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
IFS=$'\n'
total=0

for line in $($SMARTCTL --scan)
do
    total=$(($total+1))
done

echo '{'
echo '    "data": ['
for line in $($SMARTCTL --scan)
do
    total=$(($total-1))
    OLD_IFS=$IFS
    IFS='#' read -r -a device_info <<< "$line"
    SMART_DEVICE_NAME=$(trim "${device_info[0]}")
    SMART_DEVICE_SHORT_NAME=$(echo $SMART_DEVICE_NAME | cut -d " " -f 1)
    IFS=$OLD_IFS

    if [[ $SMART_DEVICE_NAME =~ "/dev/sd" ]]; then
        SMART_DEVICE_NAME=$(echo ${SMART_DEVICE_NAME} | sed -r 's/ -d scsi//')
    fi

    for info in $(eval $SMARTCTL -i $SMART_DEVICE_NAME)
    do
	[[ $info =~ "SMART support is: Available" ]] && SMART_AVAILABLE=true
	[[ $info =~ "SMART support is: Enabled" ]]   && SMART_ENABLE=true
	[[ $info =~ "Device Model:" ]]               && SMART_DEVICE_MODEL="${info#Device Model:     }"
	[[ $info =~ "Product:" ]]                    && SMART_DEVICE_MODEL="${info#Product:              }"
	[[ $info =~ "Serial Number" ]]               && SMART_DEVICE_SERIAL="${info#Serial Number:    }"
    done

    SMART_DEVICE_SHORT_NAME="${SMART_DEVICE_MODEL} (${SMART_DEVICE_NAME})"
    SMART_DEVICE_STATUS=$(eval $SMARTCTL -H $SMART_DEVICE_NAME | grep -iP 'SMART Health Status|SMART overall-health self-assessment test result' | cut -d ':' -f 2 | tr -d ' ')
    echo -ne '        { "{#SMART_DEVICE_SHORT_NAME}":"'${SMART_DEVICE_SHORT_NAME}'", "{#SMART_DEVICE_NAME}":"'${SMART_DEVICE_NAME}'", "{#SMART_DEVICE_MODEL}":"'${SMART_DEVICE_MODEL}'", "{#SMART_DEVICE_SERIAL}":"'${SMART_DEVICE_SERIAL}'"}'

    if [ $total -ne 0 ]; then
	echo -ne ","
    fi

    echo
done

echo '    ]'
echo '}'

