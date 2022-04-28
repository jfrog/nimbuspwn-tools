#!/bin/bash

readonly NETWORKD_DISPATCHER="networkd-dispatcher"
readonly SYSTEMD_NETWORKD="systemd-networkd"
readonly SYSTEMD_NETWORK_USER="systemd-network"

readonly EXPLOITABLE="This system may be vulnerable to Nimbuspwn."
readonly EXPLOITABLE_PROCS="${EXPLOITABLE} The following processes are running as the systemd-network user:"
readonly EXPLOITABLE_SUID="${EXPLOITABLE} The following executables are set to run as systemd-network user (via setuid):"
readonly EXPLOITABLE_SUID_SBIN="${EXPLOITABLE} The following /sbin executables are set to run as systemd-network user (via setuid):"
readonly EXPLOITABLE_SUID_USR_SBIN="${EXPLOITABLE} The following /usr/sbin executables are set to run as systemd-network user (via setuid):"
readonly NOT_EXPLOITABLE="It's unlikely that this system is vulnerable to Nimbuspwn,"

is_process_running() {
    if pgrep -f "$1" > /dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

main() {
    # Check basic attack prerequisites
    echo "Checking networkd-dispatcher process..."
    if ! is_process_running $NETWORKD_DISPATCHER; then
        echo "${NOT_EXPLOITABLE} since the vulnerable process networkd-dispatcher is not running."
        return 0
    fi

    echo "Checking systemd-networkd process..."
    if is_process_running $SYSTEMD_NETWORKD && systemctl list-unit-files | grep enabled | grep -wq $SYSTEMD_NETWORKD; then
        echo "${NOT_EXPLOITABLE} since systemd-networkd is running and enabled, preventing takeover of org.freedesktop.network1 messages"
        return 0
    fi

    exploitable=false
    # Check processes that run as systemd-network
    echo "Checking systemd-network user processes..."
    networkd_procs=$(ps --no-headers -u $SYSTEMD_NETWORK_USER)
    if [ ! -z "$networkd_procs" ]; then
        echo "$EXPLOITABLE_PROCS"
        echo -e "$networkd_procs\n" 
        exploitable=true
    fi

    # Check SUID binaries that run as systemd-network
    if [ "$1" = "--full-suid" ]; then
    	echo "Checking setuid-executables under / ... (may take a while)"
        suid_executables=$(find / -user $SYSTEMD_NETWORK_USER -perm -4000 -exec ls -ldb {} \; 2>/dev/null)
        if [ ! -z "$suid_executables" ]; then
            echo "$EXPLOITABLE_SUID"
            echo -e "$suid_executables\n"
            exploitable=true
        fi
    else
    	echo "Checking setuid-executables under /sbin ... "
        suid_executables_sbin=$(find /sbin -user $SYSTEMD_NETWORK_USER -perm -4000 -exec ls -ldb {} \;)
        if [ ! -z "$suid_executables_sbin" ]; then
            echo "$EXPLOITABLE_SUID_SBIN"
            echo -e "$suid_executables_sbin\n"
            exploitable=true
        fi

        echo "Checking setuid-executables under /usr/sbin ... "
        suid_executables_usr_sbin=$(find /usr/sbin -user $SYSTEMD_NETWORK_USER -perm -4000 -exec ls -ldb {} \;)
        if [ ! -z "$suid_executables_usr_sbin" ]; then
            echo "$EXPLOITABLE_SUID_USR_SBIN"
            echo -e "$suid_executables_usr_sbin\n"
            exploitable=true
        fi
    fi

    if [ "$exploitable" = false ]; then
        echo "${NOT_EXPLOITABLE} since the systemd-network user doesn't seem to be in use."
    fi

    return 0
}

main "$@"