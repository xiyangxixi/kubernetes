##### 手动部署kubernetes 部分参考: https://blog.51cto.com/bigboss/2153651

##### 环境说明

* kubernetes version: 1.15.2
* etcd version: 3.3.9
* docker version: 19.03.2
* os version: CentOS7.6
* ca directory: /etc/kubernetes/ssl/
* install directory: /usr/local/bin

|number|ip|role|
|---|---|---|
|1|1.1.1.1|master etcd flannel|
|2|1.1.1.2|node etcd flannel|
|3|1.1.1.3|node etcd flannel|

文件下载地址:["文件下载地址"](https://pan.baidu.com/s/1TPKUs-vWTyoo4VKwtv9cjA)

##### 整个安装步骤 具体看每个文件夹的内容

0. prepare
1. docker
2. etcd
3. flannel
4. master(kube-apiserver kube-controller-manager kube-proxy kubelet kube-scheduler)
5. node(与master的kubelet kube-proxy类似)
