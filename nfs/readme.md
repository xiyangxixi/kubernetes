##### 搭建nfs

```
rpm -qa | grep nfs
rpm -qa | grep rpcbind
服务端：yum -y install nfs-utils rpcbind
mkdir -p /export/nfs chmod 666 /export/nfs/   
vim /etc/exports  
/export/nfs 10.10.1.0/24(rw,no_root_squash,no_all_squash,sync)
systemctl enable rpcbind.service
systemctl enable nfs-server.service
systemctl restart rpcbind
systemctl restart nfs
安装客户端：yum -y install nfs-utils
挂载: mount -t nfs 1.1.1.1:/opt/test /opt/test
处理无法umount的问题：fuser -m -v /data/  然后kill -9 pid
```

##### 使用nfs来作为storageclass

* 如上搭建nfs并测试nfs是否可以正常挂载
* 测试nfs是否可以被pv使用，即test-nfs-pv.yaml
* 测试pvc是否可以正常使用由nfs提供的pv，即test-nfs-pvc.yaml
* 创建nfs privisioner，即nfs-previsioner.yaml
* 创建nfs privisioner相关的账户与权限,即nfs-previsioner-sa.yaml
* 创建storageclass,即nfs-sc.yaml
* 测试nfs storageclass,即test-sc-pvc.yaml
* 用demo测试nfs storageclass是否可用,即test-sc-nfs-demo.yaml test-sc-nfs-demo-svc.yaml