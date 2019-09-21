##### 安装master

1. 准备kubernetes相关的证书 在master上准备好拷贝至其他服务器
```
mkdir -pv /etc/kubernetes/ssl
其中包括
-->ca-csr.json 
cfssl gencert -initca ca-csr.json | cfssljson -bare ca
-->kube-apiserver-csr.json
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=kubernetes kube-apiserver-csr.json | cfssljson -bare kube-apiserver
-->kube-controller-manager-csr.json
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=kubernetes kube-controller-manager-csr.json | cfssljson -bare kube-controller-manager
-->kube-scheduler-csr.json
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=kubernetes kube-scheduler-csr.json | cfssljson -bare kube-scheduler
-->kube-proxy-csr.json
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=kubernetes kube-proxy-csr.json | cfssljson -bare kube-proxy
-->admin-csr.json
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=kubernetes admin-csr.json | cfssljson -bare admin
-->复制证书到/etc/kubernetes/ssl目录，把ssl压缩拷贝至其他服务器
cp ca*.pem admin*.pem kube-proxy*.pem kube-scheduler*.pem kube-controller-manager*.pem kube-apiserver*.pem /etc/kubernetes/ssl
```
2. 下二进制文件压缩并移动到/usr/local/bin
```
https://github.com/kubernetes/kubernetes/blob/master/CHANGELOG-1.15.md
```
3. 安装命令自动补全
```
yum install -y bash-completion
source /usr/share/bash-completion/bash_completion
source <(kubectl completion bash)
echo "source <(kubectl completion bash)" >> ~/.bashrc
```
4. 生成kubeconfig,使用 TLS Bootstrapping.
```
export BOOTSTRAP_TOKEN=$(head -c 16 /dev/urandom | od -An -t x | tr -d ' ')

cat > /etc/kubernetes/token.csv << EOF
${BOOTSTRAP_TOKEN},kubelet-bootstrap,10001,"system:kubelet-bootstrap"
EOF

cd /etc/kubernetes

export KUBE_APISERVER="https://1.1.1.1:6443"

kubectl config set-cluster kubernetes \
--certificate-authority=/etc/kubernetes/ssl/ca.pem \
--embed-certs=true \
--server=${KUBE_APISERVER} \
--kubeconfig=kubelet-bootstrap.conf

kubectl config set-credentials kubelet-bootstrap \
--token=${BOOTSTRAP_TOKEN} \
--kubeconfig=kubelet-bootstrap.conf

kubectl config set-context default \
--cluster=kubernetes \
--user=kubelet-bootstrap \
--kubeconfig=kubelet-bootstrap.conf

kubectl config use-context default --kubeconfig=kubelet-bootstrap.conf

kubectl config set-cluster kubernetes \
--certificate-authority=/etc/kubernetes/ssl/ca.pem \
--embed-certs=true \
--server=${KUBE_APISERVER} \
--kubeconfig=kube-controller-manager.conf

kubectl config set-credentials kube-controller-manager \
--client-certificate=/etc/kubernetes/ssl/kube-controller-manager.pem \
--client-key=/etc/kubernetes/ssl/kube-controller-manager-key.pem \
--embed-certs=true \
--kubeconfig=kube-controller-manager.conf

kubectl config set-context default \
--cluster=kubernetes \
--user=kube-controller-manager \
--kubeconfig=kube-controller-manager.conf

kubectl config use-context default --kubeconfig=kube-controller-manager.conf

kubectl config set-cluster kubernetes \
 --certificate-authority=/etc/kubernetes/ssl/ca.pem \
 --embed-certs=true \
 --server=${KUBE_APISERVER} \
 --kubeconfig=kube-scheduler.conf

kubectl config set-credentials kube-scheduler \
--client-certificate=/etc/kubernetes/ssl/kube-scheduler.pem \
--client-key=/etc/kubernetes/ssl/kube-scheduler-key.pem \
--embed-certs=true \
--kubeconfig=kube-scheduler.conf

kubectl config set-context default \
--cluster=kubernetes \
--user=kube-scheduler \
--kubeconfig=kube-scheduler.conf

kubectl config use-context default --kubeconfig=kube-scheduler.conf

kubectl config set-cluster kubernetes \
--certificate-authority=/etc/kubernetes/ssl/ca.pem \
--embed-certs=true \
--server=${KUBE_APISERVER} \
--kubeconfig=kube-proxy.conf

kubectl config set-credentials kube-proxy \
--client-certificate=/etc/kubernetes/ssl/kube-proxy.pem \
--client-key=/etc/kubernetes/ssl/kube-proxy-key.pem \
--embed-certs=true \
--kubeconfig=kube-proxy.conf

kubectl config set-context default \
--cluster=kubernetes \
--user=kube-proxy \
--kubeconfig=kube-proxy.conf

kubectl config use-context default --kubeconfig=kube-proxy.conf

kubectl config set-cluster kubernetes \
--certificate-authority=/etc/kubernetes/ssl/ca.pem \
--embed-certs=true \
--server=${KUBE_APISERVER} \
--kubeconfig=admin.conf

kubectl config set-credentials admin \
--client-certificate=/etc/kubernetes/ssl/admin.pem \
--client-key=/etc/kubernetes/ssl/admin-key.pem \
--embed-certs=true \
--kubeconfig=admin.conf

kubectl config set-context default \
--cluster=kubernetes \
--user=admin \
--kubeconfig=admin.conf

kubectl config use-context default --kubeconfig=admin.conf


拷贝至其他服务器
```
5. 部署Kube-apiserver
```
生成service account key
openssl genrsa -out /etc/kubernetes/ssl/sa.key 2048
openssl rsa -in /etc/kubernetes/ssl/sa.key -pubout -out /etc/kubernetes/ssl/sa.pub

cat >/etc/systemd/system/kube-apiserver.service<<EOF
[Unit]
Description=Kubernetes API Service
Documentation=https://github.com/kubernetes/kubernetes
After=network.target
[Service]
EnvironmentFile=-/etc/kubernetes/config
EnvironmentFile=-/etc/kubernetes/apiserver
ExecStart=/usr/local/bin/kube-apiserver \\
 \$KUBE_LOGTOSTDERR \\
 \$KUBE_LOG_LEVEL \\
 \$KUBE_ETCD_ARGS \\
 \$KUBE_API_ADDRESS \\
 \$KUBE_SERVICE_ADDRESSES \\
 \$KUBE_ADMISSION_CONTROL \\
 \$KUBE_APISERVER_ARGS
Restart=on-failure
Type=notify
LimitNOFILE=65536
[Install]
WantedBy=multi-user.target
EOF

cat >/etc/kubernetes/config<<EOF
KUBE_LOGTOSTDERR="--logtostderr=true"
KUBE_LOG_LEVEL="--v=2"
EOF

cat >/etc/kubernetes/apiserver<<EOF
KUBE_API_ADDRESS="--advertise-address=0.0.0.0"
KUBE_ETCD_ARGS="--etcd-servers=https://1.1.1.1:2379,https://1.1.1.2:2379,https://1.1.1.3:2379 --etcd-cafile=/etc/kubernetes/ssl/ca.pem --etcd-certfile=/etc/etcd/ssl/etcd.pem --etcd-keyfile=/etc/etcd/ssl/etcd-key.pem"
KUBE_SERVICE_ADDRESSES="--service-cluster-ip-range=10.254.0.0/16"
KUBE_ADMISSION_CONTROL="--enable-admission-plugins=NamespaceLifecycle,LimitRanger,ServiceAccount,DefaultStorageClass,DefaultTolerationSeconds,MutatingAdmissionWebhook,ValidatingAdmissionWebhook,ResourceQuota"
KUBE_APISERVER_ARGS="--allow-privileged=true --authorization-mode=Node,RBAC --enable-bootstrap-token-auth=true --token-auth-file=/etc/kubernetes/token.csv --service-node-port-range=30000-40000 --tls-cert-file=/etc/kubernetes/ssl/kube-apiserver.pem --tls-private-key-file=/etc/kubernetes/ssl/kube-apiserver-key.pem --client-ca-file=/etc/kubernetes/ssl/ca.pem --service-account-key-file=/etc/kubernetes/ssl/sa.pub --enable-swagger-ui=true --secure-port=6443 --kubelet-preferred-address-types=InternalIP,ExternalIP,Hostname --anonymous-auth=false --kubelet-client-certificate=/etc/kubernetes/ssl/admin.pem --kubelet-client-key=/etc/kubernetes/ssl/admin-key.pem"
EOF

systemctl daemon-reload
systemctl enable kube-apiserver
systemctl start kube-apiserver
systemctl status kube-apiserver

```
* 配置kube-controller-manager
```
cat >/etc/systemd/system/kube-controller-manager.service<<EOF
Description=Kubernetes Controller Manager
Documentation=https://github.com/kubernetes/kubernetes
[Service]
EnvironmentFile=-/etc/kubernetes/config
EnvironmentFile=-/etc/kubernetes/controller-manager
ExecStart=/usr/local/bin/kube-controller-manager \\
 \$KUBE_LOGTOSTDERR \\
 \$KUBE_LOG_LEVEL \\
 \$KUBECONFIG \\
 \$KUBE_CONTROLLER_MANAGER_ARGS
Restart=on-failure
LimitNOFILE=65536
[Install]
WantedBy=multi-user.target
EOF

cat >/etc/kubernetes/controller-manager<<EOF
KUBECONFIG="--kubeconfig=/etc/kubernetes/kube-controller-manager.conf"
 KUBE_CONTROLLER_MANAGER_ARGS="--address=0.0.0.0 --cluster-cidr=10.96.0.0/16 --cluster-name=kubernetes --cluster-signing-cert-file=/etc/kubernetes/ssl/ca.pem --cluster-signing-key-file=/etc/kubernetes/ssl/ca-key.pem --service-account-private-key-file=/etc/kubernetes/ssl/sa.key --root-ca-file=/etc/kubernetes/ssl/ca.pem --leader-elect=true --use-service-account-credentials=true --node-monitor-grace-period=10s --pod-eviction-timeout=10s --allocate-node-cidrs=true --controllers=*,bootstrapsigner,tokencleaner"

 systemctl daemon-reload
 systemctl enable kube-controller-manager
systemctl start kube-controller-manager
systemctl status kube-controller-manager

EOF
```
* 部署kube-scheduler
```
cat >/etc/systemd/system/kube-scheduler.service<<EOF
[Unit]
Description=Kubernetes Scheduler Plugin
Documentation=https://github.com/kubernetes/kubernetes
[Service]
EnvironmentFile=-/etc/kubernetes/config
EnvironmentFile=-/etc/kubernetes/scheduler
ExecStart=/usr/local/bin/kube-scheduler \\
 \$KUBE_LOGTOSTDERR \\
 \$KUBE_LOG_LEVEL \\
 \$KUBECONFIG \\
 \$KUBE_SCHEDULER_ARGS
Restart=on-failure
LimitNOFILE=65536
[Install]
WantedBy=multi-user.target
EOF

cat >/etc/kubernetes/scheduler<<EOF
KUBECONFIG="--kubeconfig=/etc/kubernetes/kube-scheduler.conf"
KUBE_SCHEDULER_ARGS="--leader-elect=true --address=0.0.0.0"
EOF

systemctl daemon-reload
systemctl enable kube-scheduler
systemctl start kube-scheduler
systemctl status kube-scheduler

mkdir -pv /root/.kube
cp admin.conf /etc/kubernetes/
cp /etc/kubernetes/admin.conf /root/.kube/config
kubectl get no

kubectl create clusterrolebinding kubelet-bootstrap --clusterrole=system:node-bootstrapper --user=kubelet-bootstrap
```
* 待所有node都安装好之后
```
kubectl get csr

```
* 部署kubelet
```
cat > /etc/systemd/system/kubelet.service << EOF
[Unit]
Description=Kubernetes Kubelet Server
Documentation=https://github.com/kubernetes/kubernetes
After=docker.service
Requires=docker.service
[Service]
EnvironmentFile=-/etc/kubernetes/config
EnvironmentFile=-/etc/kubernetes/kubelet
ExecStart=/usr/local/bin/kubelet \\
          \$KUBE_LOGTOSTDERR \\
          \$KUBE_LOG_LEVEL \\
          \$KUBELET_CONFIG \\
          \$KUBELET_HOSTNAME \\
          \$KUBELET_POD_INFRA_CONTAINER \\
          \$KUBELET_ARGS
Restart=on-failure
[Install]
WantedBy=multi-user.target
EOF

cat > /etc/kubernetes/config << EOF
KUBE_LOGTOSTDERR="--logtostderr=true"
KUBE_LOG_LEVEL="--v=2"
EOF

cat > /etc/kubernetes/kubelet-config.yml << EOF
kind: KubeletConfiguration
apiVersion: kubelet.config.k8s.io/v1beta1
address: 1.1.1.1
port: 10250
cgroupDriver: cgroupfs
clusterDNS:
- 10.96.0.10
clusterDomain: cluster.local.
hairpinMode: promiscuous-bridge
serializeImagePulls: false
authentication:
  x509:
    clientCAFile: /etc/kubernetes/pki/ca.pem
  anonymous:
    enabled: false
  webhook:
    enabled: false
EOF

cat > /etc/kubernetes/kubelet << EOF
KUBELET_HOSTNAME="--hostname-override=1.1.1.1"
KUBELET_POD_INFRA_CONTAINER="--pod-infra-container-image=registry.cn-hangzhou.aliyuncs.com/google_containers/pause-amd64:3.1"
KUBELET_CONFIG="--config=/etc/kubernetes/kubelet-config.yml"
KUBELET_ARGS="--bootstrap-kubeconfig=/etc/kubernetes/kubelet-bootstrap.conf --kubeconfig=/etc/kubernetes/kubelet.conf --cert-dir=/etc/kubernetes/ssl"
EOF

systemctl daemon-reload
systemctl enable kubelet
systemctl restart kubelet
systemctl status kubelet

```
* 认证
```
kubectl get csr | awk '/node/{print $1}' | xargs kubectl certificate approve
```
* 部署kube-proxy
```
cat > /etc/systemd/system/kube-proxy.service << EOF
[Unit]
Description=Kubernetes Kube-Proxy Server
Documentation=https://github.com/kubernetes/kubernetes
After=network.target
[Service]
EnvironmentFile=-/etc/kubernetes/config
EnvironmentFile=-/etc/kubernetes/proxy
ExecStart=/usr/local/bin/kube-proxy \\
      \$KUBE_LOGTOSTDERR \\
      \$KUBE_LOG_LEVEL \\
      \$KUBECONFIG \\
      \$KUBE_PROXY_ARGS
Restart=on-failure
LimitNOFILE=65536
[Install]
WantedBy=multi-user.target
EOF

cat > /etc/kubernetes/proxy << EOF
KUBECONFIG="--kubeconfig=/etc/kubernetes/kube-proxy.conf"
KUBE_PROXY_ARGS="--proxy-mode=ipvs  --masquerade-all=true --cluster-cidr=172.20.0.0/16"
EOF
systemctl daemon-reload
systemctl enable kube-proxy
systemctl restart kube-proxy
systemctl status kube-proxy


```
