### Install ETCD

1. Install etcd manual

2. Generate CA


3. Generate Certs


### Howto test etcd

**check cluster health**

```
HOST=192.168.43.45
```

```
etcdctl -C https://${HOST}:2379 --ca-file /etc/ssl/etcd/ssl/ca.pem cluster-health
```

**member list**

```
etcdctl -C https://${HOST}:2379 --ca-file /etc/ssl/etcd/ssl/ca.pem member list
```
