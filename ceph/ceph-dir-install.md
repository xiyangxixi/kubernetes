##### 安装ceph  使用文件存储


* yum install -y wget
* mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.backup 
* wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.163.com/.help/CentOS7-Base-163.repo && yum clean all && yum makecache
* yum -y install epel* ntp ntpdate ntp-doc && yum update -y
* ceph.repo
```
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
```
* useradd ceph && echo "123456" |passwd --stdin ceph
* 管理端:yum install -y ceph ceph-deploy
* echo "ceph ALL = (root) NOPASSWD:ALL" | tee /etc/sudoers.d/ceph
* chmod 0440 /etc/sudoers.d/ceph
* 管理端登入ceph用户,复制公钥到所有节点: su - ceph  && ssh-keygen -t rsa && ssh-copy-id ceph@node1
* 如果端口不是默认的22端口，可以使用下面这样子
```
cat > ~/.ssh/config << EOF
Host node1
   Hostname node1
   User {username}
   Port 500
Host node2
   Hostname node2
   User {username}
   Port 500
Host node3
   Hostname node3
   User {username}
   Port 500
EOF
sudo chmod 644 ~/.ssh/config
```
* 安装(ceph用户)
```
mkdir cluster && cd cluster
ceph-deploy new node1 node2 node3 #会在当前目录下生成一个配置文件，可以根据实际情况修改
ceph-deploy install node1 node2 node3 或者用sudo yum install -y ceph ceph-radosgw代替
ceph-deploy mon create-initial #生成密钥
#### 建议挂载磁盘，这里以目录为列子
node1： sudo mkdir -pv /data/ceph/osd0
node2: sudo mkdir -pv /data/ceph/osd1
node3: sudo mkdir -pv /data/ceph/osd2

ceph-deploy osd prepare node1:/data/ceph/osd0 node2:/data/ceph/osd1 node3:/data/ceph/osd2
ceph-deploy osd activate node1:/data/ceph/osd0 node2:/data/ceph/osd1 node3:/data/ceph/osd2
#分发配置和秘钥
ceph-deploy --overwrite-conf admin node1 node2 node3
# 每个节点上面修改keyring的权限
sudo chmod +r /etc/ceph/ceph.client.admin.keyring
#----------------------------------------
#查看ceph的集群的情况
#----------------------------------------

ceph -s
ceph osd tre
```