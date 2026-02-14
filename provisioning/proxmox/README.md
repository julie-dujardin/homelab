## Proxmox Host provisioning

Setup: F2/DEL
Boot menu: F11

1. [Install Debian on encrypted ZFS](https://openzfs.github.io/openzfs-docs/Getting%20Started/Debian/Debian%20Trixie%20Root%20on%20ZFS.html)

    a. Use LUKS - ZFS native encryption causes issues in proxmox

    b. Boot pool: mirror

    c.  ```bash
        apt install openssh-server git zsh curl wget htop
        ```

2. [Install Proxmox on Debian](https://pve.proxmox.com/wiki/Install_Proxmox_VE_on_Debian_13_Trixie)
