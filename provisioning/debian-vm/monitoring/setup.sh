#! /bin/sh

for port in 9080 9100 8080; do
  sudo tailscale serve --bg --tcp $port tcp://localhost:$port
done
tailscale serve status
