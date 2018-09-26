#!/bin/bash
# Auth: JokerBui @2018

DOCKER_IP=172.28.16.12/20

cat << EOF > /usr/lib/systemd/system/docker.service
[Unit]
Description=Docker Application Container Engine
Documentation=https://docs.docker.com
After=network-online.target flanneld.service
Wants=network-online.target

[Service]
Type=notify
EnvironmentFile=-/run/flannel/docker
ExecStart=/usr/bin/dockerd
ExecReload=/bin/kill -s HUP \$MAINPID
LimitNOFILE=infinity
LimitNPROC=infinity
LimitCORE=infinity
TimeoutStartSec=0
Delegate=yes
KillMode=process
Restart=on-failure
StartLimitBurst=3
StartLimitInterval=60s

[Install]
WantedBy=multi-user.target
EOF

cat << EOF > /etc/systemd/system/docker.socket
[Unit]
Description=Docker Socket for the API
PartOf=docker.service

[Socket]
ListenStream=/var/run/docker.sock
SocketMode=0660
SocketUser=root
SocketGroup=docker

[Install]
WantedBy=sockets.target
EOF

mkdir /etc/docker

cat << EOF > /etc/docker/daemon.json
{
  "bip": "${DOCKER_IP}"
}
EOF

systemctl daemon-reload
# Pre docker service start
systemctl enable docker.socket && systemctl start docker.socket
journalctl -u docker -f &
systemctl enable docker && systemctl start docker
