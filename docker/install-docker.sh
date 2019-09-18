#! /bin/bash
set -e
yum remove docker  docker-client  docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-engine
yum install -y yum-utils device-mapper-persistent-data lvm2
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
wget http://mirror.centos.org/centos/7/extras/x86_64/Packages/container-selinux-2.74-1.el7.noarch.rpm
rpm -ivh container-selinux-2.74-1.el7.noarch.rpm  --nodeps
yum -y install docker-ce docker-ce-cli containerd.io

systemctl enable docker 
systemctl start docker