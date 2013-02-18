---
template: post.jade
theme: default
title: SDN浅谈
date: 2013-02-18 10:27
comments: true
tags: []
---

## 引言

SDN（Software Defined Network）是个有意思的概念。[ONF](https://www.opennetworking.org)（Open Network Foundation）这样定义SDN：

> In the SDN architecture, the control and data planes are decoupled, network intelligence and state are __logically__ centralized, and the underlying network infrastructure is abstracted from the applications.

![SDN architecture](/assets/img/snapshots/sdn-arch.jpg)

用普通话说就是软件独立于硬件，让硬件标准化，软件平台化，信息中心化。

### 硬件标准化/软件平台化

这概念说新颖不新颖，软件行业从OS诞生的那一天，就已经这么做了。Wintel主导的PC革命让整个行业围绕着一致的硬件体系，统一的，向后兼容的API（Windows SDK）开发硬件和软件的各种应用。用个不太恰当的类比：上图的infrastructure layer相当于PC的硬件，control layer相当于windows/SDK或*nix/POSIX，application layer相当于OS之上的各种软件。

可是网络设备行业却一直没有形成这样的生态圈。我觉得是两个方面的原因：

1. 整个行业没有意识。网络设备的优劣基本上在performance上见分晓，上流的vendor各出奇招，在ASIC设计上绞尽脑汁，所以就一直没形成标准的硬件（使用标准硬件的基本上是下流的vendor）。各个vendor在推出自己的设备时，软硬件已经紧密绑定，一定程度上把这三个layer做在了一起。
1. 大玩家没有意愿。即使有vendor意识到PC生态圈的好处，也没有驱动力这么做。你想啊，PC vendor的前车之鉴摆在那里，一旦decouple好了，自己若做不了control layer的leader，掌管着生态圈，岂不就沦为Compaq，Dell这样的纯硬件vendor，只能在供应链上比拼越来越低的行业利润。逮你你愿意吗？

所以CISCO/Juniper等一票vendor就这样软硬兼施地做了若干年，慢慢把市场培养成现在的样子：没有第三方，一切软件，从系统到应用，从package forwarding到VoIP，只能是我自己提供。所以当08年还是09年，Juniper依然壮士断腕，轰轰烈烈地推动One JUNOS，开放SDK，试图打造一个类似Windows的生态圈，似乎为时已晚，应者寥寥，因为愿意和有能力接盘的软件公司已经不多。

但是网络设备的发展的相对滞后，越来越赶不上mobile internet/cloud computing时代的步伐。成千上万的应用被不断地创造出来，就几个vendor的一帮苦逼程序猿咬牙应对，肯定是杯水车薪。

### 信息中心化

信息中心化是对传统网络的一大挑战。Internet的前身，[ARPANET](http://en.wikipedia.org/wiki/ARPANET)，在创建之初就有一个前提：这个网络是个__自制的，无中心的系统，网络遭受任何局部损失都不会影响其他部分的正常通讯__。所以，所有的RFC都围绕着这个前提来构建，所有的网络设备也遵循着这一前提来研发。

但是SDN将这一前提打破。所谓天下合久必分，分久必合。网络世界也不能免俗。Cloud computing引发的互联网革命新浪潮将计算和存储中心化，SDN顺应了这一趋势。通过硬件，软件平台的支持，信息（网络状态）被共享到一个逻辑上集中的中心。相对于去中心化的传统网络，SDN带来很多很多优势。本文将着重讨论信息中心化对网络设备的革命性意义。

温馨提示：作者对还未系统研读过关于SDN的ONF white paper，也没有实际研发过SDN相关的软件，所以本文中的一些想法均属臆测，既不完整，也不完备，可能经不起进一步的推敲，不当之处，还望指正。

<!--more-->

## 转发

网络设备的核心是转发，即packet从接口X转发到接口Y。转发的依据是选路，路由协议会告诉系统如何选路。转发最头疼的问题是link down，无论是physcial还是logic link down，对于拓扑中的一台网络设备来说，link down意味着重新选路并通知其他网络设备。这直接导致一段时间的丢包。选路时间越长，丢包越多。

link down带来两个问题：

1. 路由的收敛（convergence）。
1. 重新选路的不确定性。

先看收敛问题。一台运行OSPF（其他协议大致如此）的网络设备的convergence time大概可以这样算出：

```
Convergence = 链路状态变化发现时间 + 协议消息传递时间 + SPF计算时间 + RIB/FIB更新时间
```

所需时间：

* 链路状态变化发现时间: ~5ms
* 协议消息传递时间: LSA生成时间 + LSA发送时间 + LSA接收时间 + LSA处理时间 + 网络传递时间，~20ms+log(N) N为邻居数量
* SPF计算时间: O(L+N*log(N))，L为受影响的链路数，N为拓扑中节点数
* RIB/FIB更新时间: ~5ms

由以上公式大概可以看出，convergence的瓶颈在SPF计算和协议消息传递上，网络越大，SPF和协议消息传递所需时间越长。此外，一般网络设备对计算量大的任务，如SPF，跑在相对低优先级的task上，无形中又降低了SPF的速度。

在众多路由协议中，OSPF和IS-IS这样的链路状态协议，由于每台设备都拥有局部甚至全局的网络拓扑信息，收敛速度已算上佳。

再看重新选路的不确定性。由于拓扑中其他设备的影响，某台设备的同一条链路先后几次link down的选路不一定相同。所以，每次link down发生，路由需要重新收敛，不能依照之前的历史来做出决定。

### SDN的优势

如果能够将路由信息中心化，即一个云端计算中心实时掌握全网的拓扑状态，则可以做很多很有价值的处理。比如：

* 加快路由计算的速度。对于OSPF来说，如果SPF能过放在云端计算，计算性能将大有改观，能够支持比现有应用更大的网络。
* 预先做出某种判断。如果说加快路由计算的速度带来的好处可能被网络传输的延迟所抵消，那么，当云端拥有了整个拓扑状态时，可以预先计算出一些特定的解决方案并提前发送给设备。当符合解决方案的情况出现时，设备可以即刻应用解决方案选择特定的路由。

## 配置管理

配过防火墙，或者见过大型网络下防火墙在生产环境下实际配置的同学都知道，这玩意儿不是一个好配置的主。动辄成百上千的address book, policy, VPN等无论是CLI还是WebUI配置都是一种折磨。虽然大型的企业会顺带购买网管系统来统一配置旗下的各台设备，但那玩意还是一个局部的，纯静态的配置。

配置麻烦是传统网络设备的一大问题。

另一个问题是服务器动态迁移带来的网络管理问题。这个问题是服务器虚拟化革命带来的，现在的网络设备对此基本无解。为了便于说明，我们看下图：

![企业内部防火墙](/assets/img/snapshots/firewall.jpg)

一个典型的企业intranet会将不同部门间的访问权限分隔开，比如说engineering team只能访问engineering server，finance team只能访问finance server。传统防火墙对此表示毫无压力。

```
from eng-clients-zone to eng-server-zone any-source any-dest permit
from finance-clients-zone to finance-server-zone any-source any-dest permit
```

但是有一天，机房里的服务器全部都被虚拟化了，物理上已经没有了zone的概念。所以配置需要变成：

```
from eng-clients-zone to intranet-server-zone eng-client-ips eng-server-ips permit
from finance-clients-zone to intranet-server-zone finance-client-ips finance-server-ips permit
```

在同一台防火墙的管理下，这可以运行地很好，即使virtualized server在physical server间跑来跑去，只要IP不变，policy就不用发生改变。

但是，当网络变大，支撑业务运作的服务器和网络设备都增加时，会发生问题。想像一下，上述网络由两台防火墙保护，virtual server从一台防火墙后面迁移到另一台防火墙后会发生什么情况？

已有的配置将无法适应这种变化。管理员需要手工去调整配置。但是，virtual server的灵活性和physical server不可同日而语：一周甚至一个月内，physical server可能都不会有太多的变化（迁移，部署），但virtual server可能朝生暮死（想像一下aws）。

### SDN的优势

同样地，有了全网的实时拓扑信息后，SDN可以动态调整网络的配置，甚至都不需要人工干预。不用细谈，想想看：

1. policy auto push
1. traffic shaping
1. load balancing

顿时觉得无限可能，尽在SDN。

## Debug

没做过网络设备的人可能不知道网络软件的Debug有多么辛苦。一般软件Debug步骤：

1. 信息搜集
1. 缩小问题空间，直至找到root cause
1. goto 1

对于网络软件而言，信息搜集是一道坎，你要能拿到topology下面各个相关网络设备的配置和问题出现时的log。这绝对不是一件容易的事儿。不信你问customer escalation engineer。他们每天要死要活地抓log，一次很难成功，两次，三次成功都算苍天有眼。

就算成功抓到了需要的log，想想AT&T给你个路由震荡的issue，一个大topology下数十台设备，数兆的configuration，数十兆的log。相关的，不相关的，反正都抛给你，你死的心都有了。

### SDN的优势

SDN太有优势了，因为集中控制，所以可以：

* 指定相关的网络设备同时打开需要的debug开关（这个相当关键）
* 将log（甚至packets）收集到central cloud上
* 运行一组predefined analysis tool分析问题的所在（这个可以根据平时的case不断积累）
* 建立一个virtualized environment，replay packets

最后，可能有80%的case都能找到一个前例；剩下那20%，到engineer手上，也是narrow down的有价值的数据，甚至分析报告。


## 后记

瞎扯了一些SDN的也许不着边际的应用场景，立此存照，来年再看。我对SDN商业上的看法是：

* CISCO/Juniper推动的决心和力度不会太大，除非壮士断腕；反而是大型互联网公司，如google, amazon才是这场革命的主角。据说google在其intranet上已经将SDN/openflow的优势发挥地淋漓尽致。
* SDN的核心，central control plane很可能是个开源的标准化的system，很难为某家硬件厂商掌控。这也是我不看好CISCO/Juniper做为的原因。唯有开源和标准化，才能吸引小的硬件玩家进入并颠覆这一市场。
* 如果前一点成立，那么第三方的应用市场将有极大的想像空间，也许能催生一批又一批网络领域的Borland，Adobe，etc.

依旧例，放上一张小宝最近的游泳照，感谢你耐心读到这里：

![小宝游泳照](/assets/img/photos/baby20130218.jpg)


