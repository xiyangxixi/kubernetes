##### 部署coredns

* wget https://raw.githubusercontent.com/coredns/deployment/master/kubernetes/coredns.yaml.sed
* wget https://raw.githubusercontent.com/coredns/deployment/master/kubernetes/deploy.sh
* chmod +x deploy.sh && ./deploy.sh -i 10.96.0.10 > coredns.yml
* kubectl apply -f coredns.yml
* 跑一个nginx测试一下,见nginx.yml
* kubectl run -it --rm --restart=Never --image=infoblox/dnstools:latest dnstools
* 进去后执行nslookup nginx && nslookup kubernetes



##### 部署metrics-server

```
for file in auth-delegator.yaml auth-reader.yaml metrics-apiservice.yaml metrics-server-deployment.yaml metrics-server-service.yaml resource-reader.yaml;do wget https://raw.githubusercontent.com/kubernetes/kubernetes/v1.15.2/cluster/addons/metrics-server/$file;done
```
* 注意点 apiserver中要开启聚合
```
--requestheader-client-ca-file=/etc/kubernetes/ssl/ca.pem --requestheader-allowed-names= --requestheader-extra-headers-prefix=X-Remote-Extra- --requestheader-group-headers=X-Remote-Group --requestheader-username-headers=X-Remote-User --proxy-client-cert-file=/etc/kubernetes/ssl/metrics-proxy.pem --proxy-client-key-file=/etc/kubernetes/ssl/metrics-proxy-key.pem --enable-aggregator-routing=true
```
* 修改镜像以及启动命令 metrics-server-deployment.yaml
```
      - name: metrics-server
        image: registry.cn-hangzhou.aliyuncs.com/google_containers/metrics-server-amd64:v0.3.3
        command:
        - /metrics-server
        - --metric-resolution=30s
        # These are needed for GKE, which doesn't support secure communication yet.
        # Remove these lines for non-GKE clusters, and when GKE supports token-based auth.
        - --kubelet-port=10250
        - --kubelet-insecure-tls
        - --kubelet-preferred-address-types=InternalIP,Hostname,InternalDNS,ExternalDNS,ExternalIP


      - name: metrics-server-nanny
        image: registry.cn-hangzhou.aliyuncs.com/google_containers/addon-resizer:1.8.5

        command:
          - /pod_nanny
          - --config-dir=/etc/config
          - --cpu=100m
          - --extra-cpu=0.5m
          - --memory=100Mi
          - --extra-memory=50Mi
          - --threshold=5
          - --deployment=metrics-server-v0.3.3
          - --container=metrics-server
          - --poll-period=300000
          - --estimator=exponential
```
* resource-reader.yaml中权限设置
```
  resources:
  - pods
  - nodes
  - nodes/stats
  - namespaces
  verbs:
  - get
  - list
  - watch
```
* kubelet增加参数:--authentication-token-webhook=true
* 修改端口(我这里需要) metrics-server-deployment.yaml
```
        - --kubelet-port=10250
```