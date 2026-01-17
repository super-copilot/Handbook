
### 一、服务配置

#### 1、ECS配置
1. **更新yum源**
```
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

<table>
<tr>
<td width="50%">
    <b>Python 代码</b>
</td>
<td width="50%">
    <b>JavaScript 代码</b>
</td>
</tr>
<tr>
<td>

<pre>
def hello():
    print("Hello World")

hello()
</pre>

</td>
<td>

<pre>
function hello() {
    console.log("Hello World");
}

hello();
</pre>

</td>
</tr>
</table>

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





