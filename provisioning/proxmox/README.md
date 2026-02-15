## Proxmox Host provisioning

Setup: F2/DEL
Boot menu: F11

1. [Install Debian on encrypted ZFS](https://openzfs.github.io/openzfs-docs/Getting%20Started/Debian/Debian%20Trixie%20Root%20on%20ZFS.html)

    a. Use LUKS - ZFS native encryption causes issues in proxmox

    b. ZFS pools: mirror

    c. After first reboot:

        sudo apt install openssh-server git zsh curl wget htop tree nfs-kernel-server

2. [Install Proxmox on Debian](https://pve.proxmox.com/wiki/Install_Proxmox_VE_on_Debian_13_Trixie)

3. Install a debian VM

    a. Run `vm-cloud-init.sh` as root - edit ram, cpu, storage size.

    b. Install necessary software:

        sudo apt install git htop zsh tree qemu-guest-agent nfs-common

4. Install:
    - [oh-my-zsh](https://ohmyz.sh/#install)
    - [docker](https://docs.docker.com/engine/install/debian/)
