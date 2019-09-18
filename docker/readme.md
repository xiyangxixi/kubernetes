##### 安装docker

1. 卸载之前版本: yum remove docker  docker-client  docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-engine
2. 安装依赖: yum install -y yum-utils device-mapper-persistent-data lvm2
3. 添加yum: yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
4. 安装docker: yum -y install docker-ce docker-ce-cli containerd.io
5. 可能会提示docker-selinux问题：wget http://mirror.centos.org/centos/7/extras/x86_64/Packages/container-selinux-2.74-1.el7.noarch.rpm
6. 安装docker-selinux: rpm -ivh container-selinux-2.74-1.el7.noarch.rpm  --nodeps
7. 如果要安装指定版本: yum search docker-ce --showduplicates