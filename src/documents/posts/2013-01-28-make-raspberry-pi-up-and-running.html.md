---
layout: post
theme: default
title: Make raspberry pi up and running
date: 2013-01-28 09:59
comments: true
tags: [raspberry, hacker]
cover: /assets/files/posts/raspberry_pi.jpg
---

## 引子

心仪很久的Raspberry Pi model B终于到手。拆开相当原始的包装后，就两页说明书和一块电路板，连条电源线也没有（不过$35就能搞到这样一个好东东，你还能要求什么呢）。

![Raspberry Pi](/assets/files/snapshots/rasp.jpg)

板子上清晰地刻着 `MADE IN CHINA`，这年头，电子产品不made in china你都不好意思拿出来卖。

由于本文并非评测文章，有关Raspberry的详细说明，规格等信息请移步 [官网](http://www.raspberrypi.org/)，接下来准备好SD卡，咱们来安装系统，让Pi跑起来！

<!--more-->


## 热身活动

我们的目标是安装官网的Raspbian “wheezy”，他是一个debian的variant，为Pi特别优化。

```
$ wget http://downloads.raspberrypi.org/images/raspbian/2012-12-16-wheezy-raspbian/2012-12-16-wheezy-raspbian.zip
$ unzip 2012-12-16-wheezy-raspbian/2012-12-16-wheezy-raspbian.zip
```

注意，以上链接可能并非最新，请使用 http://www.raspberrypi.org/downloads 页面中的最新版本。

接下来需要一张SD卡装系统。由于没有准备，临时找了张几年前的4G卡。事实证明，这会要了你的老命，因为接下来的工作相当地IO intensive。建议使用class 10 16G SD卡，毕竟现在这样一张卡也就几十，一顿饭钱。

> 免责声明1：以下操作仅在osx上测试，linux用户请自行使用对应命令，且自负后果
>
> 免责声明2：以下操作具有风险，请非hacker自觉离开，如不慎损坏您的数据，作者不负连带责任

把卡插到笔记本的读卡器上，备份好数据。

在osx下运行：
```
$ diskutil list
```

ubuntu下：
```
$ cat /proc/partitions
```

找到你的sd卡对应的disk，我的是disk1。接下来是危险且耗时的命令，osx和ubuntu应该是相同的：
```
sudo dd if=/Users/tchen/software/2012-12-16-wheezy-raspbian.img of=/dev/disk1
```
注意请将img的路径替换成你刚刚解压出来的文件路径。另外一定要确保of指定的磁盘是SD卡，否则后果不堪想象。

接下来可以去洗个澡，然后悠闲地上网冲浪，因为这将是一个非常漫长的时刻（我的卡花了至少半小时），屏幕不会有进度条，没有任何反应，只有出错或者成功才有输出。

如果失败了，换张卡再试试。我试了4G和2G的古董卡各一张，都没问题。

## 点亮你的Pi

一块如此精巧的电路板在手中把玩半天，你却不能点亮它进入到hacker world，心里一定很不爽。不过，经历了地狱般的等待后，终于，SD卡烧好了，你迫不及待地将其插入Pi，然后...然后...等等，电源线呢？

呵呵，你终于想起来包装里没有电源线。说明书上说要用一个5v/1000mA的电源通过micro USB口接入。如果你有iphone的话，iphone充电器能够提供5v/1000mA的输出，剩下的，就是找根一头micro USB一头USB的线，基本上你家里会有这东西：旧手机的数据线，音箱数据线，etc.

> 注意，以下步骤不是必须，Pi缺省是打开ssh的，所以只要知道IP，就可以ssh上去配置，我只是觉得这样挺好玩，更有感觉一些

接通电源前你还需要至少接个USB键盘和有HDMI接口的显示器。前者好搞定，甭管有线无线，一般家里都有个键盘鼠标神马的（我家有个无线的键鼠套装，用于HTPC，可以用）。带HDMI接口的显示器不好找，这年头用台式机越来越少。不过，现在的电视一般都带HDMI，只好屈就一下它做为Pi的display。一切电缆连好之后，就可以插入电源了。Pi没有开机键，点亮后就开始启动，屏幕上左上角应该会出现一个大大的树莓，下面就是标准的debian输出，玩过linux的人都不陌生。一分钟左右的时间，进入到如下画面：
![Raspberry bootup menu](/assets/files/snapshots/rasp_up.jpg)

有这些配置项：
![Raspberry bootup menu](/assets/files/snapshots/rasp_menu.jpg)

你要做的最重要的两项是：

* expand_rootfs
* ssh

前者能充分利用SD卡的所有空间，后者打开ssh。然后退出config，选择不重启，进入到shell中。在shell请运行 `ifconfg` 获取Pi的IP地址。

如果没联显示器神马的，点亮后，可以到你的路由器上查找attached devices，排除那些你熟悉的，剩下的那个就是Pi了。可以ssh上去进行配置（假设Pi的IP是10.0.0.3)：
```
$ ssh pi@10.0.0.3 (password: raspberry)
Linux raspberrypi 3.2.27+ #250 PREEMPT Thu Oct 18 19:03:02 BST 2012 armv6l

The programs included with the Debian GNU/Linux system are free software;
the exact distribution terms for each program are described in the
individual files in /usr/share/doc/*/copyright.

Debian GNU/Linux comes with ABSOLUTELY NO WARRANTY, to the extent
permitted by applicable law.
Last login: Sun Jan 27 19:15:27 2013 from 10.18.92.137
$ sudo rasp-config
```
这样也能进行基本配置。记得改密码哦。

## Make It Easy

Hacker厌烦琐碎的工作。接下来，我们让Pi的使用变得舒服一些。首先，在路由器上添加一个MAC binding，把Pi的MAC地址和一个固定IP绑定起来，比如说10.0.0.3（取决于你路由器上的DHCP设置）。这样，就不会某次重启时IP突然变成其他IP，还得大费周章去寻。

接下来让ssh变得轻松些。每次输IP，还要敲密码，挺不爽，设置用密钥登入吧。假设你已经用 `ssh-keygen` 生成了密钥（如果没有，请生成）。

```
$ ssh-copy-id -i ~/.ssh/id_rsa.pub pi@10.0.0.3
```
注：osx需先用brew安装ssh-copy-id: `brew install ssh-copy-id`。

完成后，编辑下~/.ssh/config，在文件最后加入如下内容：
```
Host pi
  HostName 10.0.0.3
  user pi
```

试试 `ssh pi`，一键登入的感觉如何？

## Hacker's Time

你已经能自如登入一台700MHz（还可以最多超频到1GHz），512MB内存的全功能PC上，最赞的是这台PC只有信用卡大小。接下来能干很多事，比如说，搭个服务器。先跑个web server玩玩：

```
$ sudo aptitude update # 这是个好习惯，保先嘛
$ sudo aptitude install nginx 
$ sudo aptitude install git
$ sudo aptitude install vim
```

然后写个html文件测试，你也可以使用我写的一个小toy - cleanmyass（记得先生成rsa key，并将公钥上传到github）：
```
$ git clone git@github.com:tyrchen/cleanmyass.git
```

然后如此配置nginx：
```
server {
  listen 80;
  server_name pi.tchen.me; # you can change this to your domain.
  access_log /var/log/nginx/cleanmyass.access.log;
  error_log /var/log/nginx/cleanmyass.error.log;
  location / {
    root /home/pi/deployment/www/cleanmyass;
  }
}
```
接下来在你的笔记本上为 `/etc/hosts` 里添加指向 `pi.tchen.me` 的IP。

然后试试打开浏览器：http://pi.tchen.me/。

![帮你擦屁股](/assets/files/snapshots/cleanmyass.jpg)

呵呵，小小的恶作剧。这个页面会自动帮你从一些主要的网站自动登出，比如微博。如果你在网吧上网，可能需要这么个玩意儿。

至此，Pi可以履行一个web server的职责了。

如果你需要更强力的server端支持，比如说nodejs，可以
```
$ sudo aptitude install nodejs
```
不过这样获得的版本太低，是0.6.9。可以自己下载源码编译最新的0.8.18（撰文时最新的版本）。可惜Pi的CPU弱了写，做这样computing intensive的活儿还是有些慢，我的编译阶段花了一个多小时。如果你嫌慢，可以在笔记本上搞一套ARM的cross compiler，为Pi来编译软件。我正琢磨着要不要建一套这样的系统呢，否则想要最新的软件这样编译下去会死人的。

当然，Pi的力量不仅限于此。现在很后悔当时读在职研究生没读个硬件设计相关的专业，否则现在也许能用Pi做个r2d2神马滴，多NB~

OK，到目前为止你的Pi已经成为一台不错的超低功耗Web服务器，这也许是你的数字小家的第一步。接下来我们看看别人都用Pi做些什么，不要被自己那微不足道的成功迷了眼：

http://linuxtoy.org/archives/cool-ideas-for-raspberry-pi.html

## 延伸阅读

人性是贪婪的，看到Pi提供HDMI接口并号称支持1080p，你自然会想到能不能用它装一个 [XBMC](http://xbmc.org/)。有个18岁的小伙子已经想到了这一点，并做了一个相当棒的能够一键安装的系统。OK，欢迎来到 http://www.raspbmc.com/ 的世界。

安装raspbmc是一种享受（除了速度慢了点）。你要做的就是在笔记本上插入SD卡，然后运行：
```
$ wget http://svn.stmlabs.com/svn/raspbmc/testing/installers/python/install.py
$ chmod +x install.py 
$ sudo python install.py
```
按照提示下一步就好。

接下来把SD卡插入Pi，连上internet和电视，启动，等待3-5小时（取决于你的网速），最终XBMC会被自动安装成功。这是安装后的效果：

![raspberry bmc](/assets/files/snapshots/rasp_bmc.jpg)

可惜里面的服务大部分都被伟大的长城墙了，所以安完后我也不知道那他来干什么用，只是觉得很cool而已。哈哈，hacker's joy.

## 后记

依旧献上小宝的萌照：

![小宝](/assets/files/photos/baby20130128-1.jpg)
![小宝](/assets/files/photos/baby20130128-2.jpg)


