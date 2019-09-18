##### 安装etcd，etcdctl etcd两者版本必须一致

##### 在master上生成相关证书，再拷贝至其他服务器

1. 所有节点下载并解压移动至/usr/local/bin/：https://github.com/etcd-io/etcd/releases
```
wget https://github.com/coreos/etcd/releases/download/v3.3.9/etcd-v3.3.9-linux-amd64.tar.gz
tar -zxvf etcd-v3.3.9-linux-amd64.tar.gz
cd etcd*
mv etcdctl etcd /usr/local/bin
chmod +x /usr/local/bin/etcd*
```
2. 准备证书文件 ca-config.json etcd-ca-csr.json etcd-csr.json
3. 生成etcd-ca证书：cfssl gencert -initca etcd-ca-csr.json | cfssljson -bare etcd-ca
4. 生成etcd证书: cfssl gencert -ca=etcd-ca.pem -ca-key=etcd-ca-key.pem -config=ca-config.json -profile=kubernetes etcd-csr.json | cfssljson -bare etcd
5. 复制到etcd的证书证书目录: mkdir -pv /etc/etcd/ssl && cp etcd*.pem /etc/etcd/ssl
6. 为方便管理，注册成系统服务: etcd1.service,etcd2.service,etcd3.service
7. 启动etcd: systemctl daemon-reload && systemctl enableetcd && systemctl restart etcd
8. 查看集群健康状态
```
etcdctl --ca-file /etc/etcd/ssl/etcd-ca.pem --cert-file /etc/etcd/ssl/etcd.pem  --key-file /etc/etcd/ssl/etcd-key.pem cluster-health
```
9. 查看集群成员
```
etcdctl --ca-file /etc/etcd/ssl/etcd-ca.pem --cert-file /etc/etcd/ssl/etcd.pem  --key-file /etc/etcd/ssl/etcd-key.pem member list
```