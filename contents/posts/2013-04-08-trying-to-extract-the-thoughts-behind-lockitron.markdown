---
template: post.jade
theme: default
title: 胡思乱想之Lockitron的技术架构
date: 2013-04-08 08:53
comments: true
published: true
tags: [analysis, lockitron]
---

## 引子

有很久没有写文章了。为google I/O在airbnb寻找硅谷附近的住所时无意间遇到了Paul，[lockitron](http://lockitron.com) 的创始人。于是lockitron便吸引了我的注意力。他们的video很酷（需翻墙）：

<iframe width="640" height="360" src="http://www.youtube.com/embed/D1L3o88GKew" frameborder="0" allowfullscreen></iframe>

根据这个video及其主页的介绍，我用lean canvas大概总结了一下其要解决的问题和商业思路：[Locitron lean canvas](/canvases/2013-04-10-lockitron-canvas.html)。接下来的问题是：如果要做这样一个产品，需要什么样的技术架构？

于是，我花了些时间，深入了解lockitron，思考其特性，及特性背后的feature。我会从硬件——门锁控制器（下称controller），软件——功能与服务（下称service）两个方面来看lockitron面临的技术挑战及解决方案。由于我手头没有一个lockitron供我测试和reverse engineering，所以接下来你看到的内容，臆想的成分很大。

<!--more-->

## 硬件——门锁控制器

我是硬件的门外汉，不懂PCB，但是controller的控制电路本身想来并不太难（please correct me），但是要能通过网络控制门锁门锁，则面临三个棘手的问题：

* 如何接收（甚至发送）控制信号？
* 如何保证安全性？（信号正确无误，来自被授权的设备，且未被reply）
* 如何可靠地供电？

安全性是一个全局问题，我们最后讨论。

接受来自网络的信号从而控制机械进行开关的动作不算一件很难的事情，有线网络，WiFi，蓝牙，NFC等技术都可以做到。然而要从internet上接收控制信号，且不依赖第三个设备，可选的技术就只有有线和无线网络。有线网络不用考虑，没有易用性。所以Lockitron选择使用WiFi——感谢iPhone/iPad的普及，目前几乎有网络的家庭就会有WiFi。

但是，如何配置controller上的WiFi，使其接入到家里的WiFi网络，从而连接internet？这是我苦苦思索的一个问题。我想到以下solution：

1. 为controller额外多提供一个ethernet接口，供第一次部署时访问，就像路由器那样，默认192.168.0.1的IP地址，提供一个简单的WebUI来选择WiFi接入点及输入密码。不过这样多了额外的硬件（和外部接口），用起来也很傻。
2. 为controller提供蓝牙支持。用户可以通过手机连上去，然后在app中设置其WiFi配置。蓝牙的缺点是服务范围有点广，你对门也总能搜到这个蓝牙信号，然后搞点破坏。当然，可以在成功建立WiFi连接后自动关闭蓝牙，然后在丢失WiFi连接后再重新启动。不过似乎还是有不少漏洞。
3. NFC支持。同2。范围更近一些，应该更安全些。不过别有用心的人可以会拿着手机在你的门上扫...
4. 在面板上提供一个触摸屏。用它来进行配置工作。貌似可行，但造价一下子就上去了。
5. 提供简单的语音支持。也不是很靠谱。而且软硬件成本上去不少。

这些解决方案中要我选的话，唯一能接受的是ethernet。除了稍稍SB些，安全性/成本比是最优的。

然而看Lockitron的外观图，并没发现其有ethernet接口（或USB口）。Lockitron是怎么解决这个问题的呢？我多番查证，终于在其官方博客3/23的一篇博文中找到了答案—— [Electric Imp](http://electricimp.com/)，又是一个NB创业公司做出来的天才硬件。看看video：

<iframe width="640" height="360" src="http://www.youtube.com/embed/ezFsOBQCcPU" frameborder="0" allowfullscreen></iframe>

Imp是一个SD card大小的网络连接组件，为设备提供安全的互联网连接。Imp为设备制造商解决两个问题：

* 网络连接：Imp card有自己的OS（猜想是个定制的linux或uc/os），内建TLS支持，保证网络传输的安全
* 轻松部署：Imp有自己的BlinkUp专利技术（待批准），只要将iPhone屏幕贴着Imp，几次闪光后就可将WiFi配置传输到Imp。看这个Video：

<iframe width="640" height="360" src="http://www.youtube.com/embed/sVWlQNzU4Ak" frameborder="0" allowfullscreen></iframe>

关于Imp更多的细节请自行访问其官网。也许下次我会尝试着思考Imp的技术架构。

总之，通过使用Imp，controller解决了前两个问题。

供电是另外一个棘手的问题。一般人家的门上不会走电线，也就不可能有电源插口。另外，外部电源并不可靠，你总不想在小区停电的晚上，一个人呆在门口里，绝望地刷微博等待电力恢复吧？所以，电池供电是最好的解决方案。但是，门锁不比iPhone，你不能每天晚上给它充电，然后祈祷它一天之内都能正常工作。最终问题指向了硬件和软件的电力消耗：如何设计足够省电的软硬件，让Lockitron能正常工作一年之久？

答案还是Imp。Imp帮助Lockitron offload了很多事情。由于它能够接收来自internet的信息，比如说一个json:

```
{
  "action": "open"
}
```

通过编程，我们可以将这个消息转换成某个引脚的低电平/高电平信号，从而让controller驱动开关。所以我猜想controller的PCB比较简单，甚至用不到CPU。所以，耗电的压力主要集中在Imp上。看了下Imp的手册，idle状态下10mA以内，rx/tx状态会最高到250mA。10mA只能算是中庸，对于AA充电电池（一般2500mA左右）来说，能待机250小时，10天左右。然而Imp还支持deep sleep，在此状态下只需要6uA的电流，不考虑电池自放电，可以待机47年。在deep sleep状态下，当收到信号时，Imp会启动，连接WiFi，传输数据，然后再转回deep sleep，整个过程耗时1s左右。这对开关锁这样的非实时应用来说足够了，所以，在Imp的帮助下，Lockitron controller能够使用两节AA电池，待机至少1年。当电池电量到达某个阈值时，controller会通过led（猜测）提醒主人更换电池。

## 软件——功能与服务

我们先看看Lockitron的软件都需要做哪些事情：

* 用户和controller注册
* 权限设置（授权其他用户开锁）
* 开锁/解锁
* 事件处理（有人敲门，主人正在接近家门，etc.）
* 日志



## 手机应用

解决了以上问题，剩下的就是如何user friendly。在Video中Lockitron的控制器甚至能被各种各样的终端控制，不单单限制在手机上。但人人都有手机，所以Lockitron提供了iOS, Android甚至text message的支持。作为创业公司，Lockitron的做法很讨巧，就提供了一套手机端的html5页面。使用起来是否足够友好和流畅我不得而知，因为我只能打开login的页面。但Lockitron的控制目前还相对简单，所以WebUI足矣。


（未完待续）



