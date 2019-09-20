##### 安装flannel

1. flannel需要etcd来存储子网信息，所以先写入预定义子网段
```
etcdctl --ca-file=/etc/etcd/ssl/etcd-ca.pem --cert-file=/etc/etcd/ssl/etcd.pem --key-file=/etc/etcd/ssl/etcd-key.pem --endpoints="https://10.10.1.162:2379,https://10.10.1.163:2379,https://10.10.1.166:2379"  mkdir /kube-centos/network

etcdctl --ca-file=/etc/etcd/ssl/etcd-ca.pem --cert-file=/etc/etcd/ssl/etcd.pem --key-file=/etc/etcd/ssl/etcd-key.pem --endpoints="https://10.10.1.162:2379,https://10.10.1.163:2379,https://10.10.1.166:2379"  mk /kube-centos/network/config '{"Network":"172.20.0.0/16","SubnetLen":24,"Backend":{"Type":"vxlan"}}'
```
2. 下载二进制文件并解压移动至/usr/local/bin
```
wget https://github.com/coreos/flannel/releases/download/v0.11.0/flannel-v0.11.0-linux-arm.tar.gz
tar -zxvf flannel-v0.11.0-linux-arm.tar.gz
cd flannel*
mv flanneld /usr/local/bin/
mv mk* /usr/local/bin
chmod +x /usr/local/bin/flanneld
```
3. 注册系统服务文件见flanneld1.service flanneld2.service flanneld3.service 配置文件见flanneld
4. 修改docker.service见docker.service,其中EnvironmentFile=-/run/flannel/docker EnvironmentFile=-/run/flannel/subnet.env以及$DOCKER_NETWORK_OPTIONS需要添加
5. 先启动flannle再启动docker: systemctl daemon-reload && systemctl start flanneld && systemctl restart docker
6. 使用ip a查看docker0与flanneld是否在同一网段，ping一下其他节点的docker0ip监测是否能通
