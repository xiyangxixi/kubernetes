##### 安装kubernetes前准备工作

* 所有节点：关闭selinux和防火墙
* 所有节点：关闭swap: swapoff -a
* 所有节点：配置转发相关参数
```
cat <<EOF >  /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
vm.swappiness=0
EOF

sysctl --system
```
* 所有节点：加载ipvs模块
```
cat << EOF > /etc/sysconfig/modules/ipvs.modules 
#!/bin/bash
ipvs_modules_dir="/usr/lib/modules/\`uname -r\`/kernel/net/netfilter/ipvs"
for i in \`ls \$ipvs_modules_dir | sed  -r 's#(.*).ko.xz#\1#'\`; do
    /sbin/modinfo -F filename \$i  &> /dev/null
    if [ \$? -eq 0 ]; then
        /sbin/modprobe \$i
    fi
done
EOF

chmod +x /etc/sysconfig/modules/ipvs.modules 
bash /etc/sysconfig/modules/ipvs.modules
```
* master节点：下载证书工具cfssl
```
wget https://pkg.cfssl.org/R1.2/cfssl_linux-amd64
chmod +x cfssl_linux-amd64
mv cfssl_linux-amd64 /usr/local/bin/cfssl
wget https://pkg.cfssl.org/R1.2/cfssljson_linux-amd64
chmod +x cfssljson_linux-amd64
mv cfssljson_linux-amd64 /usr/local/bin/cfssljson
wget https://pkg.cfssl.org/R1.2/cfssl-certinfo_linux-amd64
chmod +x cfssl-certinfo_linux-amd64
mv cfssl-certinfo_linux-amd64 /usr/local/bin/cfssl-certinfo
```
* 所有节点: yum install -y conntrack-tools && yum install -y ipvsadm