---
layout: post
title: 安装全新ubuntu指南
date: 2013-11-12 22:40
comments: true
ignored: true
tags: [thought, guide]
cover: /assets/files/posts/container.jpg
---



## 准备工作

建立了一个新的服务器后，我们需要做以下事情：

如果当前是root账号，我们需要disble这个账号。

首先创建一个用户 ``tchen``：

```
useradd
```

安装vim:

```
apt-get install vim
```

更新系统的缺省editor为vim:

```
update-alternatives --config editor
```

使用 ``visudo`` 将用户加入sudoer（填入以下行）:

```
tchen   ALL=(ALL) ALL
```

然后配置 ``.ssh/config``，加入服务器：

```
Host server
  Hostname x.x.x.x
  user tchen
  IdentityFile ~/.ssh/id_rsa
```

使用 ``ssh-copy-id`` 将 ``tchen`` 的公钥传入。

```
ssh-copy-id -i ~/.ssh/id_rsa tchen@server
```

输入密码后，即可登录。

之后尝试 ``tchen`` 账户是否能够 ``sudo visudo``，如果ok，则可 disable root账号:

```
sudo passwd -l root
```


## 安装软件

先确保 ``add-apt-repository`` 可正常运行:

```
sudo apt-get install software-properties-common
```

### java

系统缺省的 ``java`` 是 openjdk，如果想要 oraclejdk。

```
sudo add-apt-repository ppa:webupd8team/java
sudo apt-get update
sudo apt-get install oracle-java7-installer
```

### golang

```
sudo add-apt-repository ppa:duh/golang
sudo apt-get update
sudo apt-get install golang
```

### nodejs

```
sudo apt-get install -y python-software-properties python g++ make
sudo add-apt-repository -y ppa:chris-lea/node.js
sudo apt-get update
sudo apt-get install nodejs
```

### docker

```
sudo apt-get install linux-image-extra-`uname -r`
sudo sh -c "wget -qO- https://get.docker.io/gpg | apt-key add -"
sudo sh -c "echo deb http://get.docker.io/ubuntu docker main > /etc/apt/sources.list.d/docker.list"
sudo apt-get update
sudo apt-get install lxc-docker
```

### nginx

```
sudo add-apt-repository ppa:nginx/stable
sudo apt-get update
sudo apt-get install nginx
```


## 安全性配置

### ssh

取消ssh password登录，只允许RSA authentication登录（执行以下操作前请确保通过RSA key可以访问ssh）：

```
$ sudo vim /etc/ssh/sshd_config
```

将如下配置修改为对应值：

```
RSAAuthentication yes
PubkeyAuthentication yes
ChallengeResponseAuthentication no
PasswordAuthentication no
UsePAM no
```

重新加载ssh：

```
$ sudo service ssh reload
```

为了进一步增强ssh安全性，可以把默认端口修改为别的端口（如果使用aws请在aws console中把新端口加入防火墙访问列表）：``Port 22``。

### ufw

