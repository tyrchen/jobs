---
layout: post
theme: default
title: 创建下一代家用防火墙vMars
date: 2013-03-05 14:14
comments: true
tags: [firewall, thought, startup]
cover: /assets/files/posts/fire_alarm.jpg
---

> 2013-03-05 作者按：这是个胡思乱想的产品，写于2013-02-06，我尝试者把我系统领域的知识和互联网上的实践结合起来，看看能擦出什么火花。一直keep private，是想有朝一日做成自己的下一个创业项目。但最近的精力放在这上的很少，目前可预见的一年内自己也没有能耐去handle这样一个项目（主要是涉及的链条太广）。所以干脆将其open，或许可以激发能干成这事的人。

<!--more-->

## 硬件

Raspberry Pi开启了一个新的廉价低功耗全功能PC时代。仅需要$35，你可以轻松拥有一个700MHz，512M memory，可轻松运行debian/archlinux的PC。如果扣去销售和管理运营成本，我们有理由相信Pi的BOM可能会在$25-$32间。

如果我们将Pi的video/audio/usb/gpio等子系统去掉，加多四个百兆网口及wifi芯片，内嵌1G flash memory，将其打造成一个可用的网络平台，以我并不专业的大脑猜测，BOM大概还在$30左右的区间。也就是说，花费不到200元，我们有了一个打造家用防火墙的硬件基础。

(当然，这里没有考虑设计SoC的费用，毕竟没法直接使用Pi现成的硬件设计了)

## 软件

对于一个家庭而言，很少会部署多个网络设备，这会增大使用难度。但用户必然会使用的网络设备是无线路由器。所以家用防火墙首先要支持无线路由器的基本功能，否则无法立足。无线路由器的基本功能包括：

* PPPoE/Static IP接入。这是最基本的功能，供用户接入互联网。
* WIFI access point。这也是最基本的功能，供家用设备无线接入局域网。
* DHCP server。自动为家用设备分配局域网IP。
* NAT。将局域网IP转换成WAN IP。
* DNS relay。中继从其他设备发送过来的DNS请求。
* uPnP（可选）。
* MAC address binding（可选）。
* Traffic Shaping/Metoring（可选）。

支持以上功能后，一款基本的防火墙还应该支持以下安全功能：

* policy。简言之，允许或拒绝什么样的traffic通过。比如：拒绝从孩子的IP去访问 http://sex.com (假设这个域名存在)
* screen。阻止常见的网络攻击。
* Intrusion detection: 未知攻击的检测和防范。
* Application Identification: 鉴别具体的应用以阻止不当内容。如允许家庭网络访问facebook，但阻止一个名为drug play（假想的应用）的facebook第三方应用。
* URL Filtering/Content Filtering: URL过滤和内容过滤。

要满足以上feature，先不做任何performance的考虑，仅从最快速度打造一个demo product的角度看，我们有十足的理由选用open source软件：

* OS: debian (Raspbian) 或者 archlinux
* Policy based firewall: iptables
* Intrusion detection: snort

当然还有linux下的all-in-one的software suite可选，如 [ipfire](http://www.ipfire.org/)。

选用linux是因为上述的网络协议linux已经都很好地支持，仅需要做必要的配置就可以使用。iptables和snort能够提供必要的网络安全支持，安装和配置就不在这里详述。有兴趣的同学可以移步 [这里](http://www.instructables.com/id/Raspberry-Pi-Firewall-and-Intrusion-Detection-Syst/)。

当然，选用GPL license的software对商业项目来说有些风险，因为任何修改于其source code的redistribution都需要开源。所以真要商业使用的话，要么将防火墙端代码开源，要么换bsd license的software stack，如freebasd + ipfirewall, etc. 如果demo product被验证成功，我会选择走BSD的路子，更可控一些。

## 互联网

上面讲了一大堆和系统相关的内容，好像跟互联网没半毛钱关系。其实，之所以将这个防火墙称为下一代防火墙，重头戏就在互联网这里。

### 部署

传统无线路由器部署起来很麻烦，对于不是精通网络的人来说，简直就是一场痛苦的审判。而防火墙的复杂性更甚于此。不过，构架在开源软件之上，我们可以很方便地构架一套web ui，通过cloud的方式来方便用户部署。听起来是不是很SDN?

vMars的部署方式：

1. 用户把防火墙拆箱，连到笔记本上，并将防火墙的WAN口连接到xDSL接口（或者小区宽带）上，就可以访问 http://10.0.0.1 进行配置。管理界面只有一页，就是提供宽带商给你的用户名/密码。直至接入到互联网。
1. 防火墙连接云端的服务器（假想中的 https://vmars.com），提示用户使用产品的序列号注册一个用户ID。用户ID就是云端的通行证。
1. 接下来vmars.com问用户几个问题，然后帮助用户初步配置防火墙的无线功能。之后让用户将家中的设备连接到防火墙的SSID下。用户点击完成后，会以可视化的方式显示都有什么样的设备连接到了防火墙（这点应该可实现，因为每个mac地址的前24bit对应一个vendor，如：http://aruljohn.com/mac.pl。但具体到device如ipad, iphone则需构建一个db）。
1. 用户可以为device起别名，并标记已连接的设备为：『家长』，『孩子』，『朋友』。『家长』的设备可以访问本地网络（Intranet），并且可以无限制访问外网（Internet）；『孩子』的设备可以访问本地网络，并可以有限制访问外网；『朋友』的设备只能访问外网。
1. 接下来vmars.com会根据进一步的偏好设置为用户生成合适的安全配置，并推送到防火墙端。
1. 至此，配置完成，防火墙开始工作。以后新增的设备连接SSID后重复4-5步即可。

部署的整个过程用户不需要知道什么是policy，什么是application identification，什么是端口，只用做一些选择题就足够了。这样，即使对于小白用户也能最大化保护家庭网络的安全。

### 自动更新（配置推送）

防火墙的更新以及配置推送都由vmars.com发起。防火墙端和vmars.com端保持一个长期的TCP连接，中断后自动重连。当vmars.com有最新的virus/spam/malware的definition lib时，会自动通过连接push到防火墙，根据用户网络状况而按需变化的配置也会即时推送到防火墙端。

### 日志分析

在用户许可的情况下，每X（X>=5）分钟，设备将一些采样日志信息（可关闭），统计信息和识别出的疑似攻击信息传输到vmars.com。每个用户ID下有10G免费的日志空间。

日志信息用于分析用户的网络安全状况。

统计信息可以帮助用户可视化地看到自己家庭网络的使用状况。比如说过去一周在各个时间段网络使用的状况。vmars.com据此可以生成优化的网络配置，供用户选择使用。比如说，20:00-22:30将带宽优先提供给优酷，爱奇艺，乐视。

疑似攻击信息用于鉴定攻击行为。收集此类信息可以为用户提供更安全的网络保护。

### 自动VPN

用户可以指定一个白名单，在名单内的网站访问都将通过VPN tunnel。白名单采用UGC方式生成，一般不需要用户自己撰写。

或者根据配置，当某次访问持续无响应时，防火墙对该网站将自行切换至VPN tunnel，如果得到响应，则将该网站自动加入到VPN白名单。

由于占用了很多服务器资源，自动VPN将会是一个收费项目。相信该功能在天朝将会广受欢迎。

温馨提示：请不要将该功能用于一切形式的爬墙，否则后果自负 ^_^

### 家长控制

介个么，也可以做成一个收费项目，让家庭网络对孩子无毒无害（这可是护花育苗，造福千秋万载的丰功伟业啊）。

其实基本功能实现不难，就是一个Url filtering，难的是构建database（不过可以购买第三方滴）。Url filtering（使用了好的database）能够过滤99%的有害信息，比如涉黄的网站。

但Url filtering无法过滤你孩子的朋友在facebook发表的不良信息，或者在snapchat上发的裸照。所以我们还需要content filtering。这个也有现成的技术买，是个integration的活儿。

### 其他功能

如果实现了以上基本功能，vMars项目就能够赚到钱的话，那么，还有很多很多tier 2的功能可以进一步增加ARPU，比如说将防火墙拓展成topset，NAS，成为家庭网络的一个无可替代的中心等。当然，vMars还有更大的野心，我就不献丑了。:)

## 商业模式

一直在想这个要不要说，但看到这里，聪明的你应该也已经猜到了：IAAS，Infrastructure as a Service。没错，卖硬件是假，卖服务是真。一次性的硬件可以不赚钱（为了占领市场），但持续的服务赚钱。和运营商一样，vMars喜欢ARPU，Average Revenue Per User。我希望月ARPU是￥15或$5。

在别人的市场，别人的玩法下，一个创新的项目是很难长大的，除非你定义一种新的玩法。vMars的商业模式颠覆了诸如tplink, netgear等vendor一贯的做法。可行与否，交由市场和用户来判定。

## 后记

站着说话不腰痛，以分析家的角度来看一个项目貌似如此简单，但真正做起来，呵呵，做过的人偷笑一下，将会是一场备受折磨的旅程。做系统可不比做互联网，花3个月时间掌握一门语言和框架，就能做出看上去相当不错的产品（我的teamspark第一版仅仅用了几个晚上），但做系统，没有一定时间的积淀和历练，很难做好，甚至根本无从下手。

放张小宝的照片，这小妞现在在我怀里不愿躺着，经常自己就半坐起来，太厉害了。每周游一次泳，现在已经是游泳健将啦。

![小宝](/assets/files/photos/baby20130303.jpg)







