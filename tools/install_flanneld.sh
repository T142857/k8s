#!/bin/bash
# Auth: JokerBui @2018

K8S_MASTER_01={IP}
K8S_MASTER_02={IP}
K8S_MASTER_03={IP}
PLANNET_ETH=eth0
EXTERNAL_IP={IP}
CA_FILE=/etc/ssl/etcd/ssl/ca.pem
CERT_FILE=/etc/ssl/etcd/ssl/member-labs-k8s-master-02.pem
KEY_FILE=/etc/ssl/etcd/ssl/member-labs-k8s-master-02-key.pem

wget https://github.com/coreos/flannel/releases/download/v0.10.0/flannel-v0.10.0-linux-amd64.tar.gz
tar zxf flannel-v0.10.0-linux-amd64.tar.gz
rm -rf flannel-v0.10.0-linux-amd64.tar.gz
mv flanneld /usr/bin/flanneld

/usr/bin/flanneld -version

cat /boot/config-`uname -r` | grep CONFIG_VXLAN

cat << EOF > /usr/lib/systemd/system/flanneld.service
[Unit]
Description=Flanneld overlay address etcd agent
After=network.target
After=network-online.target
Wants=network-online.target
Requires=etcd.service
Requires=flanneld.service
After=etcd.service
Before=docker.service

[Service]
Type=notify
EnvironmentFile=/etc/sysconfig/flanneld
EnvironmentFile=-/etc/sysconfig/docker-network
ExecStart=/usr/bin/flanneld-start \$FLANNEL_OPTIONS
ExecStartPost=/usr/libexec/flannel/mk-docker-opts.sh -k DOCKER_NETWORK_OPTIONS -d /run/flannel/docker
Restart=on-failure

[Install]
WantedBy=multi-user.target
WantedBy=docker.service
EOF

echo "" > /etc/sysconfig/flanneld
cat << EOF > /etc/sysconfig/flanneld

FLANNEL_ETCD_ENDPOINTS="https://${K8S_MASTER_01}:2379,https://${K8S_MASTER_02}:2379,https://${K8S_MASTER_03}:2379"
FLANNEL_ETCD_PREFIX="/coreos.com/network"
FLANNEL_OPTIONS="-etcd-cafile=${CA_FILE} -etcd-certfile=${CERT_FILE} -etcd-keyfile=${KEY_FILE} -iface=${PLANNET_ETH} -public-ip=${EXTERNAL_IP} -ip-masq=true"

EOF

mkdir -p /opt/cni/bin && cd /opt/cni/bin
wget https://github.com/containernetworking/cni/releases/download/v0.6.0/cni-amd64-v0.6.0.tgz
tar zxf cni-amd64-v0.6.0.tgz

rm -rf cni-amd64-v0.6.0.tgz

mkdir -p /etc/kubernetes/cni/net.d
mkdir -p /etc/cni/
/usr/bin/ln -sf /etc/kubernetes/cni/net.d /etc/cni/net.d

cat << EOF > /etc/kubernetes/cni/net.d/10-containernet.conf
{
    "name": "podnet",
    "type": "flannel",
    "delegate": {
        "forceAddress": true,
        "isDefaultGateway": true,
        "hairpinMode": true
    }
}
EOF

# Show flanneld log/output
journalctl -u flanneld -f &
# Re-load systemd
systemctl daemon-reload
# Enable the service and start the flanneld service
systemctl enable flanneld && systemctl start flanneld
