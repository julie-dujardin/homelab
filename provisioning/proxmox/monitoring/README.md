# Proxmox Monitoring

Systemd service units for Prometheus exporters running on Proxmox host.

## Exporters

| Service | Port | Releases |
|---|---|---|
| node_exporter | 9100 | https://github.com/prometheus/node_exporter/releases |
| smartctl_exporter | 9633 | https://github.com/prometheus-community/smartctl_exporter/releases |
| zfs_exporter | 9134 | https://github.com/pdf/zfs_exporter/releases |
| nut_exporter | 9199 | https://github.com/DRuggeri/nut_exporter/releases |

## Installation

Create the shared service user:

```bash
useradd --system --no-create-home --shell /usr/sbin/nologin node_exporter
```

Download the binary for each exporter from the releases page above, place it in `/usr/local/bin/`, and install the service unit:

```bash
cp <exporter>.service /etc/systemd/system/
systemctl daemon-reload
systemctl enable --now <exporter>
```

node_exporter can be installed with package manager.
