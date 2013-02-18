---
template: post.jade
theme: default
title: 创建下一代家用防火墙
date: 2013-02-06 02:04
comments: true
published: false
tags: []
---

这是个胡思乱想的产品。我尝试者把我系统领域的知识和互联网上的实践结合起来，看看能擦出什么火花。

## 硬件

Raspberry Pi开启了一个新的廉价低功耗全功能PC时代。仅需要$35，你可以轻松拥有一个700MHz，512M memory，可轻松运行debian/archlinux的PC。如果扣去销售和管理运营成本，我们有理由相信Pi的BOM可能会在$25-$32间。

如果我们将Pi的video/audio/usb/gpio等子系统去掉，加多四个网口及wifi芯片，内嵌1G flash memory，将其打造成一个可用的网络平台，有理由相信，BOM大概还在$30左右的区间。也就是说，花费不到200元，我们有了一个打造家用防火墙的硬件基础。

(当然，这里没有考虑设计SoC的费用，毕竟没法直接使用Pi现成的硬件设计了)

## 软件

对于一个家庭而言，很少会部署多个网络设备，这会增大使用难度。但用户必然会使用的网络设备是无线路由器。所以家用防火墙首先要支持无线路由器的基本功能，否则无法立足。无线路由器的基本功能包括：

* PPPoE/Static IP接入。这是最基本的功能，供用户接入互联网。
* WIFI access point。这也是最基本的功能，供家用设备无线接入局域网。
* DHCP server。自动为家用设备分配局域网IP。
* NAT。将局域网IP转换成WAN IP。
* DNS relay。中继从设备发送过来的DNS请求。
* uPnP（可选）。
* MAC address binding（可选）。
* Traffic Shaping/Metoring（可选）。

支持以上功能后，一款基本的防火墙还应该支持以下安全功能：

* policy。简言之，允许或拒绝什么样的traffic通过。比如：拒绝从孩子的IP去访问 http://sex.com (假设这个域名存在)
* screen。阻止常见的网络攻击。
* Intrusion detection: 未知攻击的检测和防范。

要满足以上feature，先不做任何performance的考虑，仅从最快速度打造一个产品的角度看，我们有十足的理由选用open source软件：

* OS: debian (Raspbian) 或者 archlinux
* Policy based firewall: iptables
* Intrusion detection: snort

选用linux是因为上述的网络协议linux已经都很好地支持，仅需要做必要的配置就可以使用。iptables和snort能够提供必要的网络安全支持，安装和配置就不在这里详述。有兴趣的同学可以移步 [这里](http://www.instructables.com/id/Raspberry-Pi-Firewall-and-Intrusion-Detection-Syst/)。

## 互联网

上面讲了一大堆和系统相关的内容，好像跟互联网没半毛钱关系。其实，之所以将这个防火墙称为下一代防火墙，重头戏就在互联网这里。

### 部署

传统无线路由器部署起来很麻烦，对于不是精通网络的人来说，简直就是一场痛苦的审判。而防火墙的复杂性更甚于此。不过，构架在开源软件之上，我们可以很方便地构架一套web ui，通过cloud的方式来方便用户部署。

* 用户把防火墙拆箱，连接到xDSL接口上，就可以访问 http://10.0.0.1 进行配置。系统会要求用户提供xDSL的用户名/密码。直至接入到互联网。
* 防火墙连接云端的服务器，提示用户注册一个用户ID。用户ID就是云端的通行证。
* 基本配置。
* 高级配置。

### 自动更新（配置推送）

### 日志分析

### 

