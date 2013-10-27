---
layout: post
theme: default
title: Openflow简介
date: 2013-02-21 13:57
comments: true
tags: [SDN, technology]
cover: /assets/files/posts/sdn.jpg
---

[上一篇文章](/posts/2013-02-18-sdn-elementatory-introduction.html)简单介绍了SDN及其应用场景，臆测的成分大些。本文谈谈SDN的基石：openflow。

我们知道，SDN的核心是将control plane（下文统称controller）和data plane（下文统称oSwitch，openflow switch）分离，由一个中央集权的controller（好比一个军团的将领）指挥成百上千的oSwitch（好比千千万万的士兵），共同完成网络中数据的传输。而openflow，as a protocol，是这套体系正常运作的基石。

本文难度稍大，可能不适合没有网络设备基础知识的读者阅读。我会在下节中稍微讲一些基础概念，如果无法理解，则不建议读下去。

<!--more-->

## 网络基础知识

* 网络设备（下文统称device）的运作遵循 [ISO OSI 7层模型](http://zh.wikipedia.org/wiki/OSI%E6%A8%A1%E5%9E%8B)，但网络设备本身一般只关心：port (physical layer)，ethernet/VLAN header (link layer) [1]，IP header (network layer) layer，TCP/UDP header (transport layer)。有些设备会继续深入到application layer，如IPS，这里略过不表。
* Ingress port：packets从device的哪个接口进入。
* Egress port：packets从device的哪个接口转发出去。
* Vlan：将局域网逻辑上分成不同的虚拟网络，网络之间相互隔离。详见 [虚拟局域网](http://zh.wikipedia.org/wiki/Vlan)。
* Switch：根据destination MAC/vlan id转发packets的设备。一般会在网络中学习MAC地址和port的对应关系，构建一个二层转发表（forwarding database, or FDB）。
* Router：根据destination IP address转发packets的设备。一般会通过路由协议来学习网络中IP地址和port [2]的对应关系，构建一个三层转发表（routing table/forwarding information table, or RIB/FIB）。
* Firewall：根据5 tuple（src IP/src port/dst IP/dst port/protocol）及ingress port转发packets的设备。一般会通过配置静态策略（policy）来决定packets如何转发。在TCP/UDP连接建立时会创建session，构建一个四层转发表（session table）来使能双向数据的转发。
* unicast, broadcast, multicast这些概念就不多说，翻翻教科书就知道了。
* packets处理方法：
  * 转发（可以是unicast, broadcast, multicast），总之把包转到egress port。
  * 丢弃：不满足转发要求，在device上丢弃，如找不到路由。
  * enqueue：放入队列等待后续处理。比如要做traffic shaping。
  * 修改packet并reinject：根据规则对packet进行修改，如做source NAT（对源地址做网络地址转换），或者terminate VPN（将外层VPN包头去掉），再将packets以一个新的ingress port丢回device处理。

如果到这里还没有晕的话，可以继续读下去。

## Openflow Packets处理

openflow定义了oSwitch端如何协同controller来处理网络中的packets。这包含两个部分：1) oSwitch端packets处理逻辑 2) oSwitch转发依据，即oSwitch和controller之间的protocol。本文重点讨论再oSwitch端，packets是如何处理的。

### 解决问题的思路

我们先放着openflow不表，看看网络设备（switch，router，firewall）进行packets处理的共性，如下图所示：
![network device packet processing](/assets/files/charts/firewall-2.jpg)

* 它们都有一张 **table**（或者叫database）做为决策依据。
* table建立的依据是一系列的 **rule**。
* packets到达时，尝试 **match** table中的某个entry。
* 如果match不到任何entry，会尝试根据rule来创建entry，无法创建，就丢弃。
* 如果match到，则根据entry中的 **action** 来决定后续的处理。


这样做的好处是：

* 低耦合，高内聚，每个部分解决一个问题。
* 便于硬件化。如上图的TLU，TCU，TAU，为performance可以部分或全部硬件化。

以相对复杂的firewall为例，看看packets实际是如何处理的：

拓扑很简单：
![firewall session](/assets/files/charts/firewall-1.jpg)

1. client 1.1.1.1发起一个到server 2.2.2.2的SYN请求（TCP连接，端口为12345->80），firewall得到这个SYN packet后，进行Table Lookup，因为是第一次请求，所以找不到对应的entry。
1. SYN packet进入到Table Creation Unit，查找有没有相关的rule来建立entry
，结果找到一条，于是entry被创建出来，action是forward。
1. SYN packet进入到Table Action Unit，按照entry的action进行处理，所以包被转发到2.2.2.2。
1. 服务器收到SYN packet后，发送SYN/ACK，SYN/ACK packet到达firewall，进行Table Lookup，找到一个entry。
1. SYN packet进入到Table Action Unit，按照entry的action进行处理，所以包被转发给client。

理解了这一思路后，openflow的packets处理方法就很容易明白了。

### Flow Table

openflow关心从L1-L4的所有packet header，从这点上看，oSwitch端的很多处理和firewall很像。

![openflow packet](/assets/files/charts/packet.jpg)

openflow定义了能够match L1-L4 的flow entry：

![openflow entry](/assets/files/charts/openflow-entry.jpg)

其中，假定instructions使用64bit，那么整个entry大小为76bytes，如果能够支持1M的flow，那么flow table会消耗76M内存。

当packets到达时，openflow是如何match并处理呢？openflow-spec的这张图讲的很明白，我就不多说了：

![openflow match，截取自openflow-spec](/assets/files/charts/openflow-match.jpg)

openflow允许系统中存在一到多张flow table并且他们之间以一种pipeline的方式运行。

![openflow pipeline，截取自openflow-spec](/assets/files/charts/openflow-pipeline.jpg)

什么情况下一个packet从一张flow table里出来，进入另一张flow table呢？有不少这样的case，我们说一个比较容易理解的。

~假定flow table 1存放IPSec VPN tunnel的flow entry，flow table 2存放普通flow entry。当一个IPSec packet进入flow table 1后match对应的flow entry，其instruction为：1) decryption 2) FWD to flow table 2。当packet被解密，inner ip packet重见天日时，就可以用flow table 2中的flow entry进行转发。~

```
注：这个理解可能有些错误，因为openflow规定flow table是有序的，但这个VPN in的例子如果换成VPN out的例子则flow table的顺序正好相反，所以和openflow的spec violate...等笔者搞明白些再回过头来修订这个例子
```
Update:

看Open vSwitch时想到一种multi table的模式：即L2，L3，L4各一张table。这说得过去，而且各个flow table是严格有序的。

### Instructions

当packet match到一个flow entry后，要执行对应的instructions，openflow定义了如下instruction：

* Apply-Actions: 对packet立即执行某些action。
* Clear-Actions: 将packet上的action set清空。
* Write-Actions: 修改/添加packet上的action set。
* Write-Metadata: 修改flow entry的metadata。
* Goto-Table: 将packet转到另外一张flow table。

单独理解instructions有些困难，请继续往下读。

### Action Set

每个packet都有一个action set，初始时为空，当match flow entry时被修改。如果所有instruction都执行完，且没有后续的Goto-Table instruction时，packet上的action set被执行（~~这里也有个疑问，set一般是无序的，但action的执行必定有序，执行的先后对结果影响很大，我们姑且认为是顺序执行吧~~）。所以上述的instruction大部分实在操作packet上的action set，即定义我们如何进一步处理这个packet。

Action的执行按照如下顺序：

1. copy TTL inwards
1. pop tag
1. push tag
1. copy TTL outwards
1. decrement TTL
1. modify packet (apply all set-field actions)
1. qos
1. group
1. output

具体action的列表和作用请参考openflow-spec的p13-16。

我们举一个简单的例子，你在公司访问google.com（假定IP是203.208.46.200）。你的局域网IP是10.0.0.222，ISP分配给你公司的公网IP是22.22.22.22。对于这样一个很常见的网络访问，openflow需要应用如下actions：

* pop VLAN tag (if any)
* decrement TTL
* modify src IP from 10.0.0.222 to 22.22.22.22
* modify src port from X to Y
* output

## Openflow Table Installation

上文详述了openflow的flow table如何定义，如何match和怎样处理packets，完全是data plane的事儿。读者一定有一个疑问，那么flow table是如何install到oSwtich中？

这个问题的答案也是SDN的精华所在。我们知道，传统的网络设备，即使将data plane和control plane完全分离到不同的board上，还是在同一台设备中做决策（control plane）及执行决策（data plane）。flow table的installation是由每台网络设备自行决定。而openflow在这里将control plane完全分隔，在oSwitch/Controller之间运行protocol来传递消息，比如说：

1. flow entry installation
1. flow entry deletion

我们用下图来诠释oSwitch和Controller间如何来协作进行packet forwarding：

![openflow entry installation and forwarding](/assets/files/charts/openflow-reactive.jpg)

1. 客户端发出一个packet，到达oSwitch。
1. oSwitch match flow table失败，packet enqueue，同时发送flow entry inquiry给controller。
1. Controller获取相关的路由信息。
1. Controller发送flow entry到各个相关的oSwitch。
1. packet被依次forward到下一个oSwitch，直至到达destination。

当然，这是很被动的处理方式，first packet的latency会很高。其实也可以采取主动模式，Controller收集到拓扑信息后主动向各个oSwitch发送计算好的flow entries。

具体protocol的细节就不在本文详述，看spec就好了。


## 参考文档

[1] open flow spec: http://www.openflow.org/documents/openflow-spec-v1.1.0.pdf

[2] open flow white paper: http://www.openflow.org/documents/openflow-wp-latest.pdf
 
## 脚注

[1] 这里指LAN主要使用的link layer protocol；WAN不在本文讨论之列

[2] interface更为准确，但这里就不引入新概念了

## 后记

送上小宝照片一枚。

![小宝](/assets/files/photos/baby20130221.jpg)
