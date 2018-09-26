#!/bin/bash
# Auth: JokerBui @2018

HOST=labs-k8s-master-01
IP=172.28.48.21
SSL_CONF=openssl_1.conf

mkdir /root/etcd-certificate
cd /root/etcd-certificate

cat <<EOF > ${SSL_CONF}
[req]
req_extensions = v3_req
distinguished_name = req_distinguished_name

[req_distinguished_name]

[ v3_req ]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
subjectAltName = @alt_names

[ ssl_client ]
extendedKeyUsage = clientAuth, serverAuth
basicConstraints = CA:FALSE
subjectKeyIdentifier=hash
authorityKeyIdentifier=keyid,issuer
subjectAltName = @alt_names

[ v3_ca ]
basicConstraints = CA:TRUE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
subjectAltName = @alt_names
authorityKeyIdentifier=keyid:always,issuer

[alt_names]
DNS.1 = localhost
DNS.2 = ${HOST}
IP.1 = ${IP}
IP.2 = 127.0.0.1
EOF


CONFIG=`echo $PWD/${SSL_CONF}`
openssl genrsa -out member-${HOST}-key.pem 2048
openssl req -new -key member-${HOST}-key.pem -out member-${HOST}.csr -subj "/CN=${HOST}" -config ${CONFIG}
openssl x509 -req -in member-${HOST}.csr -CA ca.pem -CAkey ca-key.pem -CAcreateserial -out member-${HOST}.pem -days 3650 -extensions ssl_client -extfile ${CONFIG}

chmod -Rv 550 /etc/ssl/etcd/
chmod 440 /etc/ssl/etcd/ssl/*.pem
chown -Rv etcd:etcd /etc/ssl/etcd/
chown -Rv etcd:etcd /etc/ssl/etcd/*
chown etcd:etcd /var/lib/etcd/