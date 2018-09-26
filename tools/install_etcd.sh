#!/bin/bash
# Auth: JokerBui @2018

mkdir -p /var/lib/etcd
curl -# -LO https://github.com/coreos/etcd/releases/download/v3.3.8/etcd-v3.3.8-linux-amd64.tar.gz
tar xf etcd-v3.3.8-linux-amd64.tar.gz
chown -Rh root:root etcd-v3.3.8-linux-amd64
find etcd-v3.3.8-linux-amd64 -xdev -type f -exec chmod 0755 '{}' \;
cp etcd-v3.3.8-linux-amd64/etcd* /usr/bin/

useradd etcd
chown -R etcd:etcd /var/lib/etcd

cat <<EOF > /etc/systemd/system/etcd.service
[Unit]
Description=etcd
After=network.target

[Service]
Type=notify
User=etcd
EnvironmentFile=/etc/etcd.env
ExecStart=/usr/bin/etcd
NotifyAccess=all
Restart=always
RestartSec=10s
LimitNOFILE=40000

[Install]
WantedBy=multi-user.target
EOF

sysctl --system
systemctl enable etcd && systemctl start etcd
systemctl status etcd
