#!/bin/bash

# This file is part of netscripts.
#
# netscripts is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# netscripts is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with netscripts.  If not, see <https://www.gnu.org/licenses/>.

ETC_DIR="/etc/netscripts"
CONFIG_DIR="${ETC_DIR}/scripts"
AUTOSTART_DIR="${ETC_DIR}/autostart"

function error() {
    printf -- "ERROR: %s\n" "${*}"
    exit 1
}

read -r -d '' USAGE_STRING <<-EOF
Netscripts is a shell-script oriented way of managing network devices.

Usage: ns <interface name> <action>
       ns (enable|disable) <interface name> <action>
       ns (help|usage)

EOF

read -r -d '' HELP_STRING <<-EOF
To use netscripts, all you need to do is place a script into ${CONFIG_DIR}
with the name: <interface>-<action>. For example, a script called 'eth0-up'
will be run when 'ns eth0 up' is called.

To enable a script to be run on system start up, you can run 'ns enable
<interface name> <action>'. This will symlink the file<interface_name>-<action>
into ${AUTOSTART_DIR}. Under the hood, all this does is create a symlink from
the ${CONFIG_DIR} directory to the ${AUTOSTART_DIR} directory. To disable a
script from autostarting, invoke it with the same parameters but the 'enable'
keyword replaced with 'disable'.

EOF

function usage() {
    printf -- "\n%s\n\n" "${USAGE_STRING}"
    exit 0
}

function help() {
    printf -- "\n%s\n\n%s\n\n" "${USAGE_STRING}" "${HELP_STRING}"
    exit 0
}

[[ -d "${ETC_DIR}" ]] || error "Cannot find ${ETC_DIR}"
[[ -d "${CONFIG_DIR}" ]] || error "Cannot find ${CONFIG_DIR}"
[[ -d "${AUTOSTART_DIR}" ]] || error "Cannot find ${AUTOSTART_DIR}"

# Validate and check arguments
if [[ "${#}" == "0" ]] || [[ "${1}" == "usage" ]]; then
    usage
fi

if [[ "${1}" == "help" ]]; then
    help
fi

# Check to see if we need to enable a script
if [[ "${1}" == "enable" ]]; then
    INTF="${2}"
    ACTION="${3}"
    FILE_NAME="${CONFIG_DIR}/${INTF}-${ACTION}"
    SYMLINK_NAME="${AUTOSTART_DIR}/${INTF}-${ACTION}"

    [[ ! -z "${INTF}" ]] || error "No interface provided! See 'ns usage' for usage information."
    [[ ! -z "${ACTION}" ]] || error "No action provided! See 'ns usage' for usage information."
    [[ -f "${FILE_NAME}" ]] || error "${FILE_NAME} does not exist!"

    printf -- "Symlinking %s into %s\n" "${FILE_NAME}" "${SYMLINK_NAME}"
    ln -sf "${FILE_NAME}" "${SYMLINK_NAME}"
     
    exit 0

elif [[ "${1}" == "disable" ]]; then
    INTF="${2}"
    ACTION="${3}"
    SYMLINK_NAME="${AUTOSTART_DIR}/${INTF}-${ACTION}"

    [[ ! -z "${INTF}" ]] || error "No interface provided! See 'ns usage' for usage information."
    [[ ! -z "${ACTION}" ]] || error "No action provided! See 'ns usage' for usage information."
    [[ -f "${SYMLINK_NAME}" ]] || error "${SYMLINK_NAME} does not exist!"

    printf -- "Removing symlink %s\n" "${SYMLINK_NAME}"
    rm "${SYMLINK_NAME}"
    RET="${?}"

    if [[ "${RET}" != "0" ]] || [[ -f "${SYMLINK_NAME}" ]]; then
        printf -- "Unable to remove symlink %s\n" "${SYMLINK_NAME}"
        exit "${RET}"
    fi

    exit 0

elif [[ "${1}" == "autostart" ]]; then
    # This is called on system boot by systemd/something to run all the scripts

    for script in "$(ls -1 ${AUTOSTART_DIR})"; do
        [[ -f "${script}" ]] || continue

        if [[ ! -x "${script}" ]]; then
            printf -- "Making %s executable" "${FILE_NAME}"
            chmod +x "${FILE_NAME}"
        fi
        $script
    done

    exit 0

else
    # Okay, if we are here we are just invoking a script
    INTF="${1}"
    ACTION="${2}"
    FILE_NAME="${CONFIG_DIR}/${INTF}-${ACTION}"

    [[ ! -z "${INTF}" ]] || error "No interface provided! See 'ns usage' for usage information."
    [[ ! -z "${ACTION}" ]] || error "No action provided! See 'ns usage' for usage information."
    [[ -f "${FILE_NAME}" ]] || error "${FILE_NAME} does not exist!"

    # Ensure the file is executable
    if [[ ! -x "${FILE_NAME}" ]]; then
        printf -- "Making %s executable.\n" "${FILE_NAME}"
        chmod +x "${FILE_NAME}"
    fi

    # Finally, execute the script
    $FILE_NAME
    RET="${?}"

    if [[ "${RET}" != "0" ]]; then
        printf -- "Script did not return successfully.\n"
    fi

    exit "${RET}"
fi
