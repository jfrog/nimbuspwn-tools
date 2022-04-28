# Nimbuspwn detector

### Overview

This tool performs several tests to determine whether the system is possibly vulnerable to [Nimbuspwn](https://www.microsoft.com/security/blog/2022/04/26/microsoft-finds-new-elevation-of-privilege-linux-vulnerability-nimbuspwn/), a vulnerability in the `networkd-dispatcher` daemon discovered by the Microsoft 365 Defender Research Team.

A system is deemed possibly vulnerable to exploitation if the following conditions are met:
1. The vulnerable service `networkd-dispatcher` service is running.
2. The `systemd-networkd` service is either not running or not set to run at next boot. Since this service owns the `org.freedesktop.network1` bus on startup, an attacker will not be able to send messages on the bus if this service is running.
3. The `systemd-network` user is in use. Specifically whether a process owned by this user is running, or that there exist [setuid](https://www.liquidweb.com/kb/how-do-i-set-up-setuid-setgid-and-sticky-bits-on-linux/)-executables owned by this user. An attacker must run code as the `systemd-network` user in order to own the `org.freedesktop.network1` bus name and exploit the vulnerability. The attacker may be able to subvert these processes and/or setuid-executables to run arbitrary code. **Note that the existence of such processes or binaries does not guarantee they can be subverted for arbitrary code execution by an attacker**.

### Usage
```
./nimbuspwn-detector.sh [--full-suid]
```

The tool will check for the preconditions mentioned in the last section.
When the `--full-suid` flag is not given, relevant setuid-executables will be searched recursively under the  `/sbin` and `/usr/sbin` directories only.
When the `--full-suid` flag is given, the search is performed recursively on the entire root volume (`/`).