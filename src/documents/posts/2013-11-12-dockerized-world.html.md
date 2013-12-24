---
layout: post
title: 对docker的深入思考
date: 2013-11-12 22:40
comments: true
ignored: true
tags: [thought]
cover: /assets/files/posts/container.jpg
---

[docker](http://docker.io) 越来越接近1.0。作为2013年最受追捧的开源软件，docker就像一把屠龙刀，将devops的功力提升了不知多少等级。虽然对 docker 仅有一些肤浅的使用，但我对它还是有很多思考。本文记录了我对 docker 的深入思考，无所谓对错，我也不知道对错，仅仅是对我自己的脑力劳动的一个记录而已。

<!--more-->

## docker是什么

如果你对 docker 一无所知，请先阅读：http://www.slideshare.net/dotCloud/why-docker。

docker（及其背后的 [linux container](http://en.wikipedia.org/wiki/LXC) )提供了轻量级的系统-应用隔离。Linux container在操作系统和应用程序间插入了一层，将应用程序和其依赖的计算资源，系统依赖（库，运行时软件）隔离开，正如Bulter Lampson所说：

> All problems in computer science can be solved by another level of indirection. - Butler Lampson

linux container 的思想跟VM类似，但VM抽象的是物理资源，其目标是操作系统不依赖于具体的硬件；linux container 抽象的是虚拟资源，其目标是应用程序不依赖于操作系统的运行时。

Docker 之于 linux container 就好比 VMWare ESX 之于 hypervisor，它提供了一套完整的 management UI。

## docker的使用场景是什么

我能想到的使用场景，也是devops一直以来的痛，在这些地方：CI，Dev infrastructure，QA testing。综合而言，就是任何跟部署相关的场景。我们以CI为例说说部署的痛点。

CI最要命的是dependency hell，比如说你的软件要支持:

* python 2.4, 2.5, 2.6
* django 1.4, 1.5, 1.6

这个简单的 dependency matrix 适配起来就有共九种情况，需要对这九种情况分别建立测试环境。使用VM能够处理这种情况，但每个VM浪费大量的磁盘空间，当 dependency matrix 到上百个适配项的量级时，VM就无能为力了（速度太慢，占用空间太多）。

travis 通过运行时动态构建 dependency 来解决VM的问题，但每次都构建新的环境，对 travis 的 performance 影响不小，很多时间都浪费在环境的构建上，而不是测试例的运行。

docker 比较好地解决了这一问题。linux container 很轻量级，启动速度在秒级，aufs 建立了洋葱式一层层仅记录差异的文件系统，这样从一个 container 派生出来的一批 containers 都共享同一份数据。VM的启动速度问题和占用空间的问题在 docker 这里都得到很好的解决。

## 我该如何在软件生命周期中使用docker
























