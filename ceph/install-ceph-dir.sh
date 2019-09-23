# 补补脑


    # 无论你想提供 Ceph对象存储和/或Ceph块设备服务至云平台 部署Ceph文件系统或者为了其他目的而使用Ceph，所有的 Ceph存储集群部署都是从设置每个Ceph节点，
    # 你的网络和Ceph存储集群开始的。一个Ceph存储集群要求至少有一个Ceph监视器和两个Ceph OSD守护进程。当运行Ceph文件系统客户端时，必须要有Ceph元数据服务器。

    # INTRO TO CEPH（介绍Ceph）

       # OSDs: Ceph的OSD守护进程（OSD）存储数据，处理数据复制，恢复，回填，重新调整，并通过检查其它Ceph OSD守护程序作为一个心跳 向Ceph的监视器报告一些检测信息。Ceph的存储集群需要至少2个OSD守护进程来保持一个 active + clean状态.（Ceph默认制作2个备份，但你可以调整它）

       # Monitors:Ceph的监控保持集群状态映射，包括OSD(守护进程)映射,分组(PG)映射，和CRUSH映射。 Ceph 保持一个在Ceph监视器, Ceph OSD 守护进程和 PG的每个状态改变的历史（称之为“epoch”）.

       # MDS: MDS是Ceph的元数据服务器，代表存储元数据的Ceph文件系统（即Ceph的块设备和Ceph的对象存储不使用MDS）。Ceph的元数据服务器使用POSIX文件系统，用户可以执行基本命令如 ls, find,等，并且不需要在Ceph的存储集群上造成巨大的负载.

     # Ceph把客户端的数据以对象的形式存储到了存储池里。利用CRUSH算法，Ceph可以计算出安置组所包含的对象，并能进一步计算出Ceph OSD集合所存储的安置组。CRUSH算法能够使Ceph存储集群拥有动态改变大小、再平衡和数据恢复的能力。




# 基础操作
# 更换163源
yum install -y wget
mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.backup && wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.163.com/.help/CentOS7-Base-163.repo && yum clean all && yum makecache

yum -y install epel* ntp ntpdate ntp-doc && yum update -y

##使用阿里云的安装
cat > /etc/yum.repos.d/ceph.repo << EOF
[Ceph]
name=Ceph packages for $basearch
baseurl=http://mirrors.aliyun.com/ceph/rpm-jewel/el7/\$basearch
enabled=1
gpgcheck=1
type=rpm-md
gpgkey=http://mirrors.aliyun.com/ceph/keys/release.asc
priority=1

[Ceph-noarch]
name=Ceph noarch packages
baseurl=http://mirrors.aliyun.com/ceph/rpm-jewel/el7/noarch
enabled=1
gpgcheck=1
type=rpm-md
gpgkey=http://mirrors.aliyun.com/ceph/keys/release.asc
priority=1

[ceph-source]
name=Ceph source packages
baseurl=http://mirrors.aliyun.com/ceph/rpm-jewel/el7/SRPMS
enabled=1
gpgcheck=1
type=rpm-md
gpgkey=http://mirrors.aliyun.com/ceph/keys/release.asc
priority=1
EOF




# 设置用户
useradd -d /home/ceph -m ceph
passwd ceph #ceph

# 安装管理端
yum install -y ceph ceph-deploy

# 添加sudo权限：
echo "ceph ALL = (root) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/ceph
sudo chmod 0440 /etc/sudoers.d/ceph

# 在admin node(deploy node)上，登入ceph账号，创建该账号下deploy node到其他各个Node的ssh免密登录设置，密码留空：

# 在deploy node上执行：
ssh-keygen
# 使用
ssh-copy-id -i ~/.ssh/id_rsa.pub remote-host

#开始部署
# 停掉防火墙
systemctl stop firewalld
systemctl disable firewalld
#关闭SELINUX
sed -i '/SELINUX/s/enforcing/disabled/' /etc/selinux/config
#设置防火墙规则
# 设置HOSTS
cat /etc/hosts
----------------------------------------
192.168.142.153  ceph-admin
192.168.142.154  ceph-node1
192.168.142.155  ceph-node2

在所有节点上面准备目录

ssh-keygen 
ssh-copy-id -i ~/.ssh/id_rsa.pub ceph-node1
ssh-copy-id -i ~/.ssh/id_rsa.pub ceph-node2
------------------------------------------
（推荐做法）修改 ceph-deploy 管理节点上的 

cat > ~/.ssh/config << EOF
Host node1
   Hostname node1
   User {username}
   Port 10022
Host node2
   Hostname node2
   User {username}
   Port 10022
Host node3
   Hostname node3
   User {username}
   Port 10022
EOF

!!!很重要
sudo chmod 644 ~/.ssh/config
#----------------------------------------
#清理环境，保证环境的干净
#----------------------------------------
ceph-deploy purge  ceph-admin ceph-node1 ceph-node2 
ceph-deploy purgedata  ceph-admin ceph-node1 ceph-node2 
ceph-deploy forgetkeys
#----------------------------------------
#开始部署ceph集群环境
#----------------------------------------
mkdir -pv ceph-cluster && cd ceph-cluster

#----------------------------------------
#创建一个名为ceph的ceph cluster 生成相关文件
#----------------------------------------
ceph-deploy new  ceph-admin ceph-node1 ceph-node2

#----------------------------------------
#在生成的ceph.conf中增加一些参数，如下：
#----------------------------------------

#[cephd@ceph-admin ceph-cluster]$ cat ceph.conf 
[global]
fsid = 0dc31d48-d5b8-4963-995d-9de4893d7a93
mon_initial_members = ceph-admin, ceph-node1, ceph-node2
mon_host = 192.168.142.153,192.168.142.154,192.168.142.155
auth_cluster_required = cephx
auth_service_required = cephx
auth_client_required = cephx
osd pool default size = 2
osd journal size = 1024 
rbd default features = 1
[osd]
osd max object name len = 256
osd max object namespace len = 64 
rbd default features = 1

#禁用rbd features
#rbd image有4个 features，layering, exclusive-lock, object-map, fast-diff, deep-flatten
#因为目前内核仅支持layering，修改默认配置
#每个ceph node的/etc/ceph/ceph.conf 添加一行
#rbd_default_features = 1
#这样之后创建的image 只有这一个feature


#----------------------------------------
#安装ceph集群
#----------------------------------------
## 可用yum install -y ceph ceph-radosgw在每个节点执行代替
ceph-deploy install  ceph-admin ceph-node1 ceph-node2

#----------------------------------------
#在管理节点上面初始化ceph的monitor在当前目录下，出现了若干*keyring，这是Ceph组件间进行安全访问时所需要的
#----------------------------------------

ceph-deploy  mon create-initial

#[cephd@ceph-admin ceph-cluster]$ ll *.keyring
#-rw------- 1 cephd cephd 113 Aug  9 17:04 ceph.bootstrap-mds.keyring
#-rw------- 1 cephd cephd  71 Aug  9 17:04 ceph.bootstrap-mgr.keyring
#-rw------- 1 cephd cephd 113 Aug  9 17:04 ceph.bootstrap-osd.keyring
#-rw------- 1 cephd cephd 113 Aug  9 17:04 ceph.bootstrap-rgw.keyring
#-rw------- 1 cephd cephd 129 Aug  9 17:04 ceph.client.admin.keyring
#-rw------- 1 cephd cephd  73 Aug  9 16:12 ceph.mon.keyring

#----------------------------------------
#在每个节点创建相应的目录和修改目录权限
#----------------------------------------
sudo mkdir -pv /data/ceph/{osd0,osd1,osd2,osd3}
sudo chown -R bqadm:bqadm /data/ceph

#----------------------------------------
#启动OSD node分为两步：prepare 和 activate。
#OSD node是真正存储数据的节点，我们需要为ceph——osd提供独立存储空间，一般是一个独立的disk。
#但我们环境不具备这个条件，于是在本地盘上创建了个目录，提供给OSD
#----------------------------------------

ceph-deploy osd prepare ceph-admin:/data/ceph/osd0 ceph-node1:/data/ceph/osd1 ceph-node2:/data/ceph/osd2 
ceph-deploy osd activate ceph-admin:/data/ceph/osd0 ceph-node1:/data/ceph/osd1 ceph-node2:/data/ceph/osd2 
#----------------------------------------
#分发配置和秘钥
#----------------------------------------
ceph-deploy admin ceph-admin ceph-node1 ceph-node2 

#----------------------------------------
# 把管理节点的配置文件与keyring同步至其它节点
#----------------------------------------

ceph-deploy --overwrite-conf admin ceph-admin ceph-node1 ceph-node2

#----------------------------------------
# 每个节点上面修改keyring的权限
#----------------------------------------
sudo chmod +r /etc/ceph/ceph.client.admin.keyring

#----------------------------------------
#查看ceph的集群的情况
#----------------------------------------

ceph -s
ceph osd tree

#----------------------------------------
#时间同步问题
# ----------------------------------------
# ceph1:~ # ceph -s
# cluster f411aff0-1b95-4496-9310-68fa6d568903
    # health HEALTH_WARN
            # clock skew detected on mon.ceph1
            # Monitor clock skew detected
     # monmap e9: 2 mons at {ceph1=147.2.208.114:6789/0,ceph2=147.2.208.44:6789/0}
            # election epoch 58, quorum 0,1 ceph2,ceph1
     # osdmap e127: 3 osds: 3 up, 3 in
      # pgmap v2318: 72 pgs, 2 pools, 0 bytes data, 0 objects
            # 105 MB used, 45941 MB / 46046 MB avail
                  # 72 active+clean
方法一
配置ntp server, 我配置了，但是不知为什么不起作用！
方法二
通过调整参数规避：
1. 在admin结点上，修改ceph.conf，添加：
mon_clock_drift_allowed = 5
mon_clock_drift_warn_backoff = 30
这两个参数请看：http://docs.ceph.com/docs/hammer/rados/configuration/mon-config-ref/#clock
mon_clock_drift_allowed设置成多少合适？可参考这条消息：
2016-07-01 17:44:14.860902 mon.0 [WRN] mon.1 ****:6789/0 clock skew 3.0706s > max 2s
2. 执行下面命令，ceph1等是monitor结点的名称
ceph-deploy --overwrite-conf admin ceph1 ceph2 ceph3
3. 重启monitor
systemctl restart ceph-mon@ceph1.service
3. 验证
ceph1:~ # ceph -w

2016-07-01 18:19:03.545418 mon.1 [INF] mon.ceph1 calling new monitor election
2016-07-01 18:19:18.653547 mon.0 [INF] mon.ceph2 calling new monitor election
2016-07-01 18:19:18.686790 mon.0 [INF] mon.ceph2@0 won leader election with quorum 0,1
2016-07-01 18:19:18.687641 mon.0 [INF] HEALTH_OK
----------------------------------------
#----------------------------------------
#配置防火墙规则
#----------------------------------------
#iptables -A INPUT -i {iface} -p tcp -s {ip-address}/{netmask} --dport 6789 -j ACCEPT
#iptables -A INPUT -i {iface}  -m multiport -p tcp -s {ip-address}/{netmask} --dports 6800:6810 -j ACCEPT
#----------------------------------------
sudo iptables -A INPUT -p tcp --dport 6789 -j ACCEPT
sudo iptables -A INPUT -m multiport -p tcp --dports 6800:6810 -j ACCEPT


-A INPUT -p tcp -m state --state NEW -m tcp --dport 6789 -j ACCEPT
-A INPUT -p tcp -m multiport --dports 6800:6810 -j ACCEPT

# 设置时间同步没小时一次
*/1 * * * * /usr/sbin/ntpdate 0.asia.pool.ntp.org