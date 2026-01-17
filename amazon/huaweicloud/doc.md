
 
#### CCE配置
1. 配置kubeconfig文件
```
# 提前已从CCE控制台下载kubectl配置文件
mv kubectl /usr/local/bin
# 配置kubectl 配置文件
mkdir -pv $HOME/.kube
mv -f kube-test-kubeconfig.yaml $HOME/.kube/config
# 查看 Kubernetes 集群信息
kubectl cluster-info
```





