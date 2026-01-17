
# 一、服务配置

## ECS配置
1. **更新yum源**
```bash
#
mkdir -pv /etc/yum.repos.d/backup
mv /etc/yum.repos.d/*.repo /etc/yum.repos.d/backup/
wget -O /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-7.repo
wget -O /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo

yum clean all
# 刷新缓存
yum makecache        
# 查看所有配置可以使用的文件，会自动刷新缓存
yum repolist all

```

## SWR配置

1. **获取AKSK**
   > admin用户给普通授权 "编程访问"
   > 普通用户 获取AK/SK密钥

2. **获取登陆密钥**
   ```bash
   printf "4UF5WKxxxxxxxxxVMWG" | openssl dgst -binary -sha256 -hmac "Uh5MYivJI4eYWhxxxxxxxxxxxxxxxxxxxxFU47Ha" | od -An -vtx1 | sed 's/[ \n]//g' | sed 'N;s/\n//'

   62fa6b37710929xxxxxxxxxxxxxxxxxxxxxxxxxxxxx569b212ac76cc6f73
   ```
3. **docker拼接密钥**
   ```bash
   # docker 拼接AK和生成的登陆密钥
   # docker login -u cn-north-4@4UF5WKAZO488JOPGVMWG -p 62fa6b37710929fc1f4b937be36295d12257637fb4449f4569b212ac76cc6f73 swr.cn-north-4.myhuaweicloud.com
   docker login -u cn-north-4@AK -p 62fa6b37710929fc1f4b937be36295d12257637fb4449f4569b212ac76cc6f73 swr.cn-north-4.myhuaweicloud.com
   ```
4. **创建secret认证**
   ```bash
   kubectl create secret docker-registry swr-huawei --docker-server=swr.cn-north-4.myhuaweicloud.com --docker-username=cn-north-4@4UF5WKAxxxxxxxxxVMWG --docker-password=62fa6b37710929fc1f4b937bexxxxxxxxxxxxxxxxxxxxxxx9b212ac76cc6f73 -n hdms-app
   ```
5. **在yaml文件添加参数 [参考文档](https://support.huaweicloud.com/cce_faq/cce_faq_00015.html#cce_faq_00015__section629791052512)**
   ```
   containers:
   imagePullSecrets:
   - name: swr-huawei
   ```

## CCE配置
1. 配置kubeconfig文件
   ```bash
   # 提前已从CCE控制台下载kubectl配置文件
   mv kubectl /usr/local/bin
   # 配置kubectl 配置文件
   mkdir -pv $HOME/.kube
   mv -f kube-test-kubeconfig.yaml $HOME/.kube/config
   # 查看 Kubernetes 集群信息
   kubectl cluster-info
   ```
2. **kubectl补全**
   ```
   yum -y install bash-completion
   kubectl completion -h
   # 临时生效
   source <(kubectl completion bash)
   # 永久生效
   echo 'source <(kubectl completion bash)' >>~/.bashrc
   # echo "source <(kubectl completion bash)" >> /root/.bashrc
   kubectl completion bash >/etc/bash_completion.d/kubectl
   ```
#### 2、ELB配置
> [参考文档](https://support.huaweicloud.com/usermanual-cce/cce_10_0014.html)

```yaml
# 例子
apiVersion: v1 
kind: Service
metadata: 
  annotations:
    kubernetes.io/elb.id: 5083f225-xxxx-xxxx-xxxx-67bd9693c4c0   # ELB ID，替换为实际值
    kubernetes.io/elb.class: performance                   # 负载均衡器类型
    kubernetes.io/elb.health-check-flag: 'off'        # 是否开启ELB健康检查功能
    kubernetes.io/elb.lb-algorithm: ROUND_ROBIN        # 后端云服务器组的负载均衡算法
  name: nginx
  labels:
    app.kubernetes.io/component: server
spec: 
  ports: 
  - name: service0
    protocol: TCP
    port: 80     #访问Service的端口，也是负载均衡上的监听器端口。 
    targetPort: 80  #Service访问目标容器的端口，此端口与容器中运行的应用强相关
  type: LoadBalancer
  selector: 
    app: nginx
```

## Containerd
> containerd安装包有多种，建议下载cri-xxxx-cni 此类型安装包

### 1. 下载安装包
```bash
wget -c https://github.com/containerd/containerd/releases/download/v1.6.24/cri-containerd-cni-1.6.24-linux-amd64.tar.gz
```
### 2. 解压并配置
```
mkdir -pv /opt/src/containerd
tar zxf cri-containerd-cni-1.6.24-linux-amd64.tar.gz -C /opt/src/containerd
```
### 3. 配置命令
```
cd /opt/src/containerd/usr/local/bin/
cp containerd ctr crictl /usr/local/bin/
# 配置服务启动文件
cp /opt/src/containerd/etc/systemd/system/containerd.service /usr/lib/systemd/system/
```
### 4. 创建配置
```
# 创建配置文件目录
mkdir -pv /etc/containerd
# 生成配置文件
containerd config default > /etc/containerd/config.toml
```
### 5. 启动服务
```bash
systemctl enable containerd
systemctl start containerd
systemctl status containerd
```
### 6. 配置runc
> 默认自带的runc需要seccomp支持，且对版本要求一致，所以建议单独下载runc里面包含了seccomp模块支持。
> runc版本会在github/containerd每个版本描述中 `Notable Updates` 说明
```bash
wget -c https://github.com/opencontainers/runc/releases/download/v1.1.9/runc.amd64 -C /opt/src/containerd/
# 拷贝runc
cp /opt/src/containerd/runc.amd64 /usr/local/sbin/runc
chmod +x /usr/local/sbin/runc
# 查看runc版本
runc -version
```
```bash
# containerd命令
# 如果拉取docker hub上镜像，镜像前需要加上docker.io

# 先查看命名空间    kubelet接管k8s.io 命名空间
ctr ns ls
# ctr -n k8s.io images list
ctr -n k8s.io i ls    # ctr image ls # crictl image list|grep app

# ctr -n k8s.io images remove docker.io/library/nginx:latest
ctr -n k8s.io i rm docker.io/library/nginx:latest

# ctr -n k8s.io images export xxx.tar docker.io/library/nginx:latest
ctr -n k8s.io i export xxx.tar docker.io/library/nginx:latest
# ctr -n k8s.io images import xxx.tar
ctr -n k8s.io i import xxx.tar

ctr i list|grep app

# ctr -n k8s.io images pull docker.io/library/nginx:latest
ctr -n k8s.io i pull docker.io/library/redis:alpine

# ctr -n k8s.io containers create docker.io/library/redis:alpine myredis
ctr -n k8s.io c create docker.io/library/redis:alpine myredis -d #在后台启动

# ctr -n k8s.io containers list
ctr -n k8s.io c ls

# ctr -n k8s.io containers info xxxx
ctr -n k8s.io c info xxxx

# ctr -n k8s.io taks list
ctr -n k8s.io t ls

# 查看任务中的进程
ctr -n k8s.io tasks ps xxxxx
ctr -n k8s.io t ps xxxx     # docker top

# 执行容器内命令
ctr -n k8s.io tasks exec -t --exec-id xxxx xxxxx sh    # docker exec

# 暂停/恢复任务
# ctr -n k8s.io tasks pause xxxx
ctr -n k8s.io t pause xxxx
# ctr -n k8s.io tasks resume xxxx
ctr -n k8s.ip t resume xxxx

# 停止/杀死任务
ctr -n k8s.io tasks kill xxxxx
ctr -n k8s.ip t kill xxxxx
ctr -n k8s.ip t kill -s SIGKILL xxxx

# 删除任务
ctr -n k8s.io tasks delete xxxxx
ctr -n k8s.io t rm xxxxx

# 删除容器
ctr -n k8s.io containers delete xxxx
ctr -n k8s.io c rm xxxx

# 快照管理
ctr -n k8s.io snapshots list

```
