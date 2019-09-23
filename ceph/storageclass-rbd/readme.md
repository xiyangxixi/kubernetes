##### 假设已经安装好了ceph 以ceph的rbd方式来提供动态存储


* kubelet节点安装ceph-common：yum -y install ceph-common
* 创建osd pool 需要在ceph的mon或者admin节点
```
ceph osd pool create kube 4096
ceph osd lspools
```
* 创建k8s访问ceph的用户 需要在ceph的mon或者admin节点
```
ceph auth get-or-create client.kube mon 'allow r' osd 'allow class-read object_prefix rbd_children, allow rwx pool=kube' -o ceph.client.kube.keyring

# 获取key 在ceph的mon或者admin节点
ceph auth get-key client.admin
ceph auth get-key client.kube

# 创建admin予kube相关的secret
kubectl create secret generic ceph-admin-secret --type="kubernetes.io/rbd" --from-literal=key=$CEPH_ADMIN_SECRET --namespace=kube-system
kubectl create secret generic ceph-kube-secret --type="kubernetes.io/rbd" --from-literal=key=$CEPH_KUBE_SECRET --namespace=default

```
* 创建storageclass
```
 cat >storageclass-ceph-rdb.yaml<<EOF
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: dynamic-ceph-rdb
provisioner: ceph.com/rbd
parameters:
  monitors: 1.1.1.1:6789,1.1.1.2:6789,1.1.1.3:6789
  adminId: admin
  adminSecretName: ceph-admin-secret
  adminSecretNamespace: kube-system
  pool: kube
  userId: kube
  userSecretName: ceph-kube-secret
  fsType: ext4
  imageFormat: "2"
  imageFeatures: "layering"
EOF
kubectl apply -f storageclass-ceph-rdb.yaml
```
* 创建pvc测试storageclass
```
 cat >ceph-rdb-pvc-sc-test.yaml<<EOF
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: ceph-rdb-claim
spec:
  accessModes:     
    - ReadWriteOnce
  storageClassName: dynamic-ceph-rdb
  resources:
    requests:
      storage: 2Gi
EOF
kubectl apply -f ceph-rdb-pvc-sc-test.yaml
```
* 创建pod来测试storageclass
```
cat >nginx-pod.yaml<<EOF
apiVersion: v1
kind: Pod
metadata:
  name: nginx-pod1
  labels:
    name: nginx-pod1
spec:
  containers:
  - name: nginx-pod1
    image: nginx:alpine
    ports:
    - name: web
      containerPort: 80
    volumeMounts:
    - name: ceph-rdb
      mountPath: /usr/share/nginx/html
  volumes:
  - name: ceph-rdb
    persistentVolumeClaim:
      claimName: ceph-rdb-claim
EOF
kubectl apply -f nginx-pod.yaml
```