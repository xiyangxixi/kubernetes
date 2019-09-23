##### ceph 安装 rbd 数据删除与恢复

* 环境说明

|id|ip|hostname|role|
|--|--|--|--|
|1|192.168.136.101|node1|mon deploy admin node|
|2|192.168.136.102|node2|mon node|
|3|192.168.136.103|node3|mon node|
|4|192.168.136.100|client|client|

1. 安装与创建rbd
* 1.1 每台主机添加ceph源,除client外都添加3块盘
* 1.2 安装时间同步chrony 每台
* 1.3 yum -y install ceph-deploy  仅deploy
* 1.4 mkdir cluster && cd cluster
* 1.5 ceph-deploy new node1 node2 node3
* 1.6 ceph-deploy install node1 node2 node3 或者用sudo yum install -y ceph ceph-radosgw
* 执行1.7的时候一定要检查一下主机名，在.ssh/config的主机名最好就是服务器本身的主机名
* 1.7 ceph-deploy  mon create-initial
* 1.8 parted /dev/sdb mklabel gpt 每台
* 1.9 parted /dev/sdb mkpart primary 1M 50%
* 1.10 parted /dev/sdb mkpart primary 50% 100%
* 1.11 chown ceph:ceph /dev/sdb1 && chown ceph:ceph /dev/sdb2
* 1.12 ceph-deploy disk zap node1:sdc node1:sdd 在deploy操作 涉及 node1 node2 node3
* 1.13 ceph-deploy  osd create node1:sdc:/dev/sdb1 node1:sdd:/dev/sdb2 在deploy操作 涉及 node1 node2 node3
* 1.14 ceph -s
* 1.15 ceph osd lspools && rbd list
* 1.16 rbd create demo-image --image-feature layering --size 10G
* 1.17 rbd resize  --image demo-image --size 15G
* 1.18 rbd resize --image demo-image --size 10G --allow-shrink
* 1.19 rbd info demo-image
2. rbd使用(客户端)
* 2.1 yum -y install ceph-commom
* 2.2 复制ceph的ceph.conf与ceph.client.admin.keyring到客户端的/etc/ceph
* 2.3 rbd map demo-image
* 2.4 lsblk && rbd showmapped
* 2.5 mkfs -t ext4 /dev/rbd0 && mkdir /data
* 2.6 mount /dev/rbd0 /data
3. 数据恢复(镜像)
* 3.1 echo "123456" >/data/test.txt && echo /data/test.txt
* 3.2 rbd snap create demo-image --snap demo-image-s1
* 3.3 rbd snap ls demo-image && rm -rf /data/test.txt
* 3.4 rbd snap rollback demo-image --snap demo-image-s1
* 3.5 umount /data && mount /dev/rbd0 /data
* 3.6 cat /data/test.txt
4. cephfs本地挂载 使用cephfs需要启动metadata
* 4.0 ceph-deploy mds create node1 node2 node3
* 4.1 yum -y install ceph-fuse
* 4.2 cephfs需要两个pool来存储元数据与数据
* 4.3 ceph osd pool create fs_data 128 && ceph osd create pool create fs_metadata 128
* 4.4 ceph osd lspools
* 4.5 ceph fs new cephfs fs_metadata fs_data
* 4.6 ceph fs ls
* 4.7 mkdir -pv /mnt/mycephfs
* 4.8 mount -t ceph node1:6789,node2:6789,node3:6789:/  /mnt/mycephfs -o name=admin,secret=xxxxx
* 4.9 df -h验证
* 4.10 卸载: umount -lf /mnt/mycephfs && rm -rf /mnt/mycephfs
5. cephfs客户端挂载(非本地挂载) 使用cephfs需要启动metadata
* 5.0 ceph-deploy mds create node1 node2 node3
* 5.1 yum -y install ceph-fuse
* 5.2 cephfs需要两个pool来存储元数据与数据
* 5.3 ceph osd pool create fs_data 128 && ceph osd create pool create fs_metadata 128
* 5.4 ceph osd lspools
* 5.5 ceph fs new cephfs fs_metadata fs_data
* 5.6 ceph fs ls
* 5.7 mkdir -pv /mnt/mycephfs
* 5.8 ceph-fuse -m node1:6789,node2:6789,node3:6789  -o nonempty  /mnt/mycephfs  [-r /xx/xxx]
6. 对象存储

10. 清理集群
* 4.1 ceph-deploy purge node1 node2 node3
* 4.2 ceph-deploy purgedata node1 node2 node3
* 4.3 ceph-deploy forgetkeys
* 4.4 rm ceph.*
