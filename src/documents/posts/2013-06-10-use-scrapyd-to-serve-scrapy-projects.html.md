---
layout: post
theme: default
title: 用scrapyd来提供crawler服务
date: 2013-06-10 07:51
comments: true
tags: [scrapy, crawler, technology]
cover: /assets/files/posts/spider.jpg
---

这是一篇即兴的短文，主要是为了记录我用 ``scrapyd`` 的心得。

之前做数据抓取，总是一个scrapy project做一个deploy，很不方便，一个一个更新起来也很麻烦，总觉得能有更好的方法去处理。今早看了看scrapyd，觉得这就是我想要的东西。

<!--more-->

## 目标

假设你有两个scrapy project：

* alpha: 其spider是alpha-spider。
* beta: 其spider是beta-spider。

你想将其做成service，在一台ubuntu server（gryffindoe）上每周定期运行。

## 前提

在gryffindoe上，安装scrapyd：

    ```
    $ lsb_release -cs
    quantal
    $ # 将 deb http://archive.scrapy.org/ubuntu quantal main 添加到sources.list中
    $ sudo vim /etc/apt/sources.list
    $ # 安装key
    $ curl -s http://archive.scrapy.org/ubuntu/archive.key | sudo apt-key add -
    $ sudo apt-get update
    $ apt-cache search scrapyd
    scrapyd-0.16 - Scrapy Service
    scrapyd-0.17 - Scrapy Service
    $ # 安装最新版本
    $ sudo apt-get isntall scrapyd-0.17
    ```

安装完成后，scrapyd就自动在gryffindoe上运行了。

## 部署scrapy项目

scrapyd默认运行在6800端口，假设gryffindoe的域名是 ``gryffindoe.com``，在你的alpha项目中，编辑 ``scrapy.cfg``:

    ```
    [deploy:gryffindoe]
    url = http://gryffindoe.com:6800/
    project = alpha
    ```

然后你可以在你的scrapy项目下查看在gryffindoe上的scrapyd的状态：
    
    ```
    $ # 查看当前scrapyd配置
    $ scrapy deploy -l
    gryffindoe                http://gryffindoe.com:6800/
    $ # 查看当前scrapyd上部署好的项目，现在还没有
    $ scrapy deploy -L gryffindoe
    ```

接着我们把 ``alpha`` 部署到 ``gryffindoe``:

    ```
    $ scrapy deploy graffindoe -p alpha
    Building egg of alpha-1370823198
    'build/scripts-2.7' does not exist -- can't clean it
    zip_safe flag not set; analyzing archive contents...
    Deploying alpha-1370823198 to http://gryffindoe.com:6800/addversion.json
    Server response (200):
    {"status": "ok", "project": "alpha", "version": "1370823198", "spiders": 1}
    $ scrapy deploy -L gryffindoe
    alpha
    ```

大功告成。进入到另一个project ``beta`` 的目录下，如法炮制:

    ```
    $ scrapy deploy graffindoe -p beta
    Building egg of beta-1370823198
    'build/scripts-2.7' does not exist -- can't clean it
    zip_safe flag not set; analyzing archive contents...
    Deploying beta-1370823198 to http://gryffindoe.com:6800/addversion.json
    Server response (200):
    {"status": "ok", "project": "beta", "version": "1370823198", "spiders": 1}
    $ scrapy deploy -L gryffindoe
    alpha
    beta
    ```

现在你打开 ``http://gryffindeo.com:6800/``，应该有如下显示：

    Scrapyd

    Available projects: alpha, beta

    Jobs
    Items
    Logs
    Documentation

## 运行spider

接下来我们可以远程指定要运行的spider了，很简单，页面上提示可以直接使用scrapyd的json API:

    ```
    $ curl http://localhost:6800/schedule.json -d project=default -d spider=somespider
    ```

对于project ``alpha``下的spider ``alpha-spider``:

    ```
    $ curl http://localhost:6800/schedule.json -d project=alpha -d spider=alpha-spider
    ```

这样，alpha-spider就开始运行了。你可以打开 ``http://gryffindeo.com:6800/`` 查看运行状态。

如果要定期运行spider，把这条命令加到cronjob里就可以了。

送上六一给小宝的礼物一枚：

<embed src="http://player.youku.com/player.php/sid/XNTY0NzQ5NDA0/v.swf" allowFullScreen="true" quality="high" width="660" height="500" align="middle" allowScriptAccess="always" type="application/x-shockwave-flash"></embed><br/>




