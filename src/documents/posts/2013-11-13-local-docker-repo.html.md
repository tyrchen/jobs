---
layout: post
title: 建立自己的docker repository
date: 2013-11-13 22:40
comments: true
tags: [tool, technology, docker]
cover: /assets/files/posts/container.jpg
---

如果你不知道docker是什么，请参考 [这个slides](http://www.slideshare.net/dotCloud/why-docker)。

在 ubuntu 下安装 docker 请参考 [官方教程](http://docs.docker.io/en/latest/installation/ubuntulinux/) 。注意，由于 docker 的核心技术是 [Linux container](http://en.wikipedia.org/wiki/LXC)，所以如果想在 osx 下安装 docker 请使用 vagrant。

<!--more-->

## 安装docker-registry

首先clone docker-registry：

```
$ git clone https://github.com/dotcloud/docker-registry
$ cd docker-registry

$ cp config_sample.yml config.yml
```

然后打开 ``config.yml``，设置dev（缺省）的storage路径为 ``/var/docker/registry``：

```
# This is the default configuration when no flavor is specified
dev:
    storage: local
    storage_path: /var/docker/registry
    loglevel: debug
```

创建这个目录：

```
$ sudo mkdir -p /var/docker/registry
$ sudo chown -R tchen /var/docker
```

docker-registry使用了python，需要以下库的支持：

```
$ sudo apt-get install build-essential python-dev libevent-dev python-pip libssl-dev
```

然后建立 ``virtualenv`` 并安装requirements：

```
$ sudo pip install virtualenv
$ virtualenv --no-site-packages venv
$ . venv/bin/activate
$ pip install -r requirements.txt
```

## 配置supervisor

如果系统没有安装supervisor，请先安装:

```
$ sudo apt-get install supervisor
```

安装完成后，配置 ``supervisor``：

```
$ sudo vim /etc/supervisor/conf.d/docker-registry.conf
```

填入以下内容：

```
[program:docker-registry]
directory=/home/dev/deployment/docker-registry
user=dev
command=/home/dev/deployment/docker-registry/venv/bin/gunicorn -b 0.0.0.0:7030 -k gevent --max-requests 100 --graceful-timeout 3600 -t 3600 -w 8 wsgi:application
redirect_stderr=true
stderr_logfile=none
stdout_logfile=/var/log/supervisor/docker-registry.log
autostart=true
autorestart=true
```

重新加载 ``supervisor`` 配置：

```
$ sudo supervisorctl
supervisor> reread
docker-registry: available
supervisor> update
docker-registry: added process group
supervisor> status
docker-registry                  RUNNING    pid 4371, uptime 0:00:01
```

这样，``docker-registry`` 服务就正常运行了。

## 配置nginx

接下来把 ``nginx`` request proxy 到 ``docker-registry`` app 就大功告成了。

```
$ sudo vim /etc/nginx/sites-available/docker-registry
```

填入以下内容：

```
server {
  listen 80;
  client_max_body_size 200m;
  server_name docker.your-domain.com;
  access_log /var/log/nginx/docker-registry.access.log;
  error_log /var/log/nginx/docker-registry.error.log;
  location / {
    proxy_pass http://localhost:7030;
    include /etc/nginx/proxy_params;
  }
}
```

然后将其加入 ``sites-enabled`` 并重启nginx：

```
$ cd /etc/nginx/sites-enabled/
$ sudo ln -s ../sites-available/docker-registry docker-registry
$ sudo /etc/init.d/nginx restart
```

把 ``docker`` 二级域名加入到你的域名服务器中，然后打开浏览器访问 ``http://docker.your-domain.com`` 就可以看到如下页面：

```
"docker-registry server (dev)"
```

至此，``docker-registry`` 就正常运行了。


接下来看看系统都有哪些 docker images：

```
(venv)tchen@docker:~$ sudo docker images
REPOSITORY                            TAG                   IMAGE ID            CREATED             SIZE
colinsurprenant/ubuntu-raring-amd64   latest                2eb422301015        6 weeks ago         91.89 MB (virtual 91.89 MB)
colinsurprenant/ubuntu-raring-amd64   raring-amd64          2eb422301015        6 weeks ago         91.89 MB (virtual 91.89 MB)
colinsurprenant/ubuntu-raring-amd64   ubuntu-raring-amd64   22ca6d4b1576        6 weeks ago         91.89 MB (virtual 91.89 MB)
ubuntu                                12.04                 8dbd9e392a96        7 months ago        131.5 MB (virtual 131.5 MB)
ubuntu                                latest                8dbd9e392a96        7 months ago        131.5 MB (virtual 131.5 MB)
ubuntu                                precise               8dbd9e392a96        7 months ago        131.5 MB (virtual 131.5 MB)
ubuntu                                12.10                 b750fe79269d        7 months ago        24.65 kB (virtual 180.1 MB)
base                                  latest                b750fe79269d        7 months ago        24.65 kB (virtual 180.1 MB)
ubuntu                                quantal               b750fe79269d        7 months ago        24.65 kB (virtual 180.1 MB)
base                                  ubuntu-12.10          b750fe79269d        7 months ago        24.65 kB (virtual 180.1 MB)
base                                  ubuntu-quantal        b750fe79269d        7 months ago        24.65 kB (virtual 180.1 MB)
base                                  ubuntu-quantl         b750fe79269d        7 months ago        24.65 kB (virtual 180.1 MB)
```

我们选择 ``base`` 对应的 image，将其 push 到自己的服务器。首先将其标记为要push到自己的服务器：

```
$ sudo docker tag b750fe79269d docker.your-domain.com/tchen/base
```

然后push:

```
$ sudo docker push docker.your-domain.com/tchen/base
The push refers to a repository [docker.your-domain.com/tchen/base] (len: 1)
Sending image list
Pushing repository docker.your-domain.com/tchen (1 tags)
Pushing 27cf784147099545

2013/11/12 03:35:18 Received HTTP code 413 while uploading layer: <html>
<head><title>413 Request Entity Too Large</title></head>
<body bgcolor="white">
<center><h1>413 Request Entity Too Large</h1></center>
<hr><center>nginx/1.4.3</center>
</body>
</html>
```

如果出现以上错误，请修改之前nginx配置中的 ``client_max_body_size 200m;``，将其扩大至能够容纳你的image。

成功后可以看到：

```
$ sudo docker images
REPOSITORY                            TAG                   IMAGE ID            CREATED             SIZE
colinsurprenant/ubuntu-raring-amd64   latest                2eb422301015        6 weeks ago         91.89 MB (virtual 91.89 MB)
colinsurprenant/ubuntu-raring-amd64   raring-amd64          2eb422301015        6 weeks ago         91.89 MB (virtual 91.89 MB)
colinsurprenant/ubuntu-raring-amd64   ubuntu-raring-amd64   22ca6d4b1576        6 weeks ago         91.89 MB (virtual 91.89 MB)
ubuntu                                12.04                 8dbd9e392a96        7 months ago        131.5 MB (virtual 131.5 MB)
ubuntu                                latest                8dbd9e392a96        7 months ago        131.5 MB (virtual 131.5 MB)
ubuntu                                precise               8dbd9e392a96        7 months ago        131.5 MB (virtual 131.5 MB)
ubuntu                                12.10                 b750fe79269d        7 months ago        24.65 kB (virtual 180.1 MB)
docker.your-domain.com/base              latest                b750fe79269d        7 months ago        24.65 kB (virtual 180.1 MB)
base                                  latest                b750fe79269d        7 months ago        24.65 kB (virtual 180.1 MB)
docker.your-domain.com/tchen             latest                b750fe79269d        7 months ago        24.65 kB (virtual 180.1 MB)
docker.your-domain.com/tchen/base        latest                b750fe79269d        7 months ago        24.65 kB (virtual 180.1 MB)
ubuntu                                quantal               b750fe79269d        7 months ago        24.65 kB (virtual 180.1 MB)
base                                  ubuntu-12.10          b750fe79269d        7 months ago        24.65 kB (virtual 180.1 MB)
base                                  ubuntu-quantal        b750fe79269d        7 months ago        24.65 kB (virtual 180.1 MB)
base                                  ubuntu-quantl         b750fe79269d        7 months ago        24.65 kB (virtual 180.1 MB)
```

本地的image就可用了，尝试一下：

```
$ sudo docker run -i -t docker.your-domain.com/tchen/base /bin/bash
```

在其他机器上要pull这个image，很简单：

```
$ sudo docker pull docker.your-domain.com/tchen/base
```



