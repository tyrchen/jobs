---
layout: post
title: 高效能程序员的七个习惯
date: 2014-03-20 22:50
comments: true
tags: [vagrant,technology]
cover: /assets/files/posts/world.jpg
---

# Vagrant share浅析

最近vagrant 1.5升级力度空前，增加了很多新功能，其中最令人瞩目的当属 ``vagrant share``。啥子意思呢？就是把你的虚拟机share给地球另一端的人。这功能很高大上啊，简直是居家旅行，远程办公的必备武器。你正在做的web app出bug了，需要帮忙？没问题，亲，把虚拟机share一下。

<!--more-->

```
➜  dockerbox  vagrant share
==> default: Detecting network information for machine...
    default: Local machine address: 127.0.0.1
    default:
    default: Note: With the local address (127.0.0.1), Vagrant Share can only
    default: share any ports you have forwarded. Assign an IP or addres to your
    default: machine to expose all TCP ports. Consult the documentation
    default: for your provider ('virtualbox') for more information.
    default:
    default: Local HTTP port: 3000
    default: Local HTTPS port: disabled
    default: Port: 2200
    default: Port: 3000
==> default: Checking authentication and authorization...
==> default: Creating Vagrant Share session...
    default: Share will be at: cheerful-beaver-2087
==> default: Your Vagrant Share is running! Name: cheerful-beaver-2087
==> default: URL: http://cheerful-beaver-2087.vagrantshare.com
==> default:
==> default: You're sharing your Vagrant machine in "restricted" mode. This
==> default: means that only the ports listed above will be accessible by
==> default: other users (either via the web URL or using `vagrant connect`).
```

我的虚机里开放了3000端口，是个web app。share好以后，别人就可以使用这个链接：``http://cheerful-beaver-2087.vagrantshare.com``，访问程序君正在调试开发的app了。（别试了，当您看到本文时，程序君已经把共享关闭喽）。

很神奇吧？

## 这是怎么做到的？

估计你有和程序君一样的问题。程序君开始捣鼓。

首先tcp dump抓包。

```
➜  appshare git:(master) ✗ tcpdump -i en0
```

内容很多，就不在这里呈现了。没有太多实质的内容，主要是下面几个步骤：

(1) DNS请求 vagrantcloud.com 获得两个IP: 107.23.21.165, 54.85.101.30

(2) 分别进行https握手

```
20:46:06.357551 IP 10.0.0.6.61158 > ec2-107-23-21-165.compute-1.amazonaws.com.https: Flags [S], seq 3383705821, win 65535, options [mss 1460,nop,wscale 4,nop,nop,TS val 922128202 ecr 0,sackOK,eol], length 0
20:46:06.968517 IP ec2-107-23-21-165.compute-1.amazonaws.com.https > 10.0.0.6.61158: Flags [S.], seq 2369287401, ack 3383705822, win 14480, options [mss 1460,sackOK,TS val 132138929 ecr 922128202,nop,wscale 8], length 0
20:46:06.968607 IP 10.0.0.6.61158 > ec2-107-23-21-165.compute-1.amazonaws.com.https: Flags [.], ack 1, win 8235, options [nop,nop,TS val 922128810 ecr 132138929], length 0
```

```
20:46:08.502461 IP 10.0.0.6.61159 > ec2-54-85-101-30.compute-1.amazonaws.com.https: Flags [S], seq 3557617978, win 65535, options [mss 1460,nop,wscale 4,nop,nop,TS val 922130332 ecr 0,sackOK,eol], length 0
20:46:09.316782 IP ec2-54-85-101-30.compute-1.amazonaws.com.https > 10.0.0.6.61159: Flags [S.], seq 1741334642, ack 3557617979, win 14480, options [mss 1460,sackOK,TS val 132128867 ecr 922130332,nop,wscale 8], length 0
20:46:09.316849 IP 10.0.0.6.61159 > ec2-54-85-101-30.compute-1.amazonaws.com.https: Flags [.], ack 1, win 8235, options [nop,nop,TS val 922131145 ecr 132128867], length 0
```

(3) 传输数据 blablabla（这不废话么）

郁闷的是vagrant考虑到数据安全性，全部采用https，所以无法窥探里面的究竟。

为什么不用Fiddler来偷窥？好吧，fillder基于.net，程序君不想在mac上装mono...

所以程序君只能靠脑子生猜这个功能是怎么实现的了。

## 我猜我猜...

可能的实现手段：

(1) 使用p2p（但vagrant显然不是这么实现的）。先放在一边。

(2) 使用tcp proxy。具体做法：

```
local http server --- local proxy --- cloud proxy ---- cloud http server
```

用户从url过来的http请求，被负载到cloud proxy，然后cloud proxy再将其relay给local proxy，local proxy再relay给local http server；http响应反之。

这个想法比较靠谱。

试着用go简单实现了一下，主要是为了验证想法。结果证实了这个方案可行：

```
local http server (8000) --- local proxy (7000) --- cloud proxy (9000) ---- cloud http server
```

由于我在本机测试，所以不需要放一个nginx在cloud http server侧，直接访问：``http://localhost:9000``即可。经过两层proxy，local http server的内容被转到浏览器上。当然，目前的代码有问题，local proxy和cloud proxy间只有一个connection，遇到keep-alive的http connection就阻塞住了...所以你看到的页面是这样(local http server跑的是我的博客）：

![proxy proxy](../assets/week12/proxy.jpg)

代码见：[appshare](https://github.com/tyrchen/appshare)

首先用Python起一个simple http server:

```
➜  out git:(master) simpleweb
Serving HTTP on 0.0.0.0 port 8000 ...
127.0.0.1 - - [20/Mar/2014 22:08:06] "GET / HTTP/1.1" 200 -
127.0.0.1 - - [20/Mar/2014 22:08:06] "GET /assets/css/app.min.css HTTP/1.1" 200 -
127.0.0.1 - - [20/Mar/2014 22:08:06] "GET /assets/images/tyr.png HTTP/1.1" 200 -
127.0.0.1 - - [20/Mar/2014 22:08:06] "GET /assets/images/shadow-separator-wide-bottom.png HTTP/1.1" 200 -
127.0.0.1 - - [20/Mar/2014 22:08:06] "GET /assets/files/posts/busy.jpg HTTP/1.1" 200 -
127.0.0.1 - - [20/Mar/2014 22:08:06] "GET /assets/js/app.min.js HTTP/1.1" 200 -
127.0.0.1 - - [20/Mar/2014 22:08:33] "GET /assets/favicon.ico HTTP/1.1" 200 -
127.0.0.1 - - [20/Mar/2014 22:08:33] "GET /assets/js/app.min.js HTTP/1.1" 200 -
```

然后启动cloud proxy：
```
➜  appshare git:(master) ✗ bin/server :7000 :9000
2014/03/20 22:07:10 Listening to clients
2014/03/20 22:07:14 A client connection &{{0x1062f280}} kicks
2014/03/20 22:07:14 Listening to webserver
2014/03/20 22:08:06 A web server connection &{{0x1062f400}} kicks
2014/03/20 22:08:06 A web server connection &{{0x1062f4c0}} kicks
2014/03/20 22:08:06 A web server connection &{{0x1062f640}} kicks
2014/03/20 22:08:06 A web server connection &{{0x1062f700}} kicks
2014/03/20 22:08:06 A web server connection &{{0x1062f7c0}} kicks
2014/03/20 22:08:06 A web server connection &{{0x1062f880}} kicks
2014/03/20 22:08:06 A web server connection &{{0x1062f940}} kicks
2014/03/20 22:08:33 A web server connection &{{0x1062fa00}} kicks
2014/03/20 22:08:33 A web server connection &{{0x1062fac0}} kicks
```

然后启动local proxy：

```
➜  appshare git:(master) ✗ bin/client :7000 :8000
2014/03/20 22:07:14 Dial to server: &{{0x1062f100}}
Request bytes:  1207
GET / HTTP/1.1
Host: localhost:8000
Connection: keep-alive
Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8
User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_2) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/33.0.1750.152 Safari/537.36
Accept-Encoding: gzip,deflate,sdch
Accept-Language: zh-CN,zh;q=0.8,en-US;q=0.6,en;q=0.4
Cookie: bdshare_firstime=1367059155378; sessionID=b33172c1ee44d1cc188c63393cbd4f4e235fc0a9; sails.sid=s%3Axyk6QFXHoeqR15ybvL4Z1dX7.QaNFa5nuM6derKoIjTMGLr5OH9DAI10xmXuLHO65iew; connect.sid=s%3Ai0O%2F4CQPGaQ27glzc7XoGDOu.pCIlLwDcK1NCNaPguY8zVFAJsKTu5I4Ri4StI5Cd0Ps; REVEL_FLASH=; REVEL_SESSION=9d3d9559107e87236af7279c814d0dee026bd376-%00_TS%3A1395459175%00; request_method=GET; _dockernotes_session=WjRrWUx6aDhNVHVCUmtWUHJVSnZnbzdhV2h5emJ3ZFJiY3NYdlA0S3NqcnZFaDUwWGwwOFVQWGxzbkVnWmU4MXErT3Jkd0kzQTA1WEdyMVlRby9kdThCMFNISlNtZVlHRE5wMGQwVmZkWk1CNHRqZGZKVzlneVo5RG1CZzRQZnM2Tm0wNmdpSVhGMndZTjZLT0JJeEZ3VkhCSUNUdkhNTnlOR093YjdDM3V3UE1OWmNUdGtmYjdkMDNWTE1vLzY5LS01WFNEcEExOHM1VHNQYkx5ZDlUb2lRPT0%3D--0ad6871648be9dce51901555efc81f075f2d78fb; sessionid=hlgkc4638sl2eza80jmgpofvckq3ctkd; djdt=hide; csrftoken=NtojvfH3vbpOdEwyAFMG4ATKML3w6gkl


2014/03/20 22:08:06 Dial to web server: &{{0x1062f300}}
Request bytes:  1206
GET /assets/css/app.min.css HTTP/1.1
Host: localhost:8000
...


2014/03/20 22:08:06 Dial to web server: &{{0x1062f580}}
Request bytes:  1207
GET /assets/images/tyr.png HTTP/1.1
Host: localhost:8000
...


2014/03/20 22:08:06 Dial to web server: &{{0x1062f6c0}}
Request bytes:  1232
GET /assets/images/shadow-separator-wide-bottom.png HTTP/1.1
Host: localhost:8000
...


2014/03/20 22:08:06 Dial to web server: &{{0x1062f840}}
Request bytes:  2427
GET /assets/files/posts/busy.jpg HTTP/1.1
Host: localhost:8000
...

GET /assets/files/posts/world.jpg HTTP/1.1
Host: localhost:8000
...


2014/03/20 22:08:06 Dial to web server: &{{0x1062f980}}
Request bytes:  1189
GET /assets/js/app.min.js HTTP/1.1
Host: localhost:8000
...


2014/03/20 22:08:06 Dial to web server: &{{0x1062fac0}}
Request bytes:  1154
GET /assets/favicon.ico HTTP/1.1
Host: localhost:8000
。。。


2014/03/20 22:08:33 Dial to web server: &{{0x1062fc00}}
Request bytes:  1189
GET /assets/js/app.min.js HTTP/1.1
Host: localhost:8000
...
```