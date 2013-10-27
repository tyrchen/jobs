---
layout: post
theme: default
title: 自动化的高效团队开发环境
date: 2013-04-25 10:26
comments: true
tags: [startup, technology, automation]
cover: /assets/files/posts/automation.jpg
---

## 引子

这两天无意翻到几个月前的Evernote笔记，看到了当时对团队开发环境的一些想法。可惜后来种种，这一想法未能得到实践，只能将其完善后公诸于众，立此存照，日后有空可以一试。

考虑这套开发环境是因为我们遇到了这些问题：

1. 开发人员的环境并不统一：dev在osx，ubuntu 11.10和ubuntu 12.04上工作，而ux在windows下工作，协调，解决问题不太方便，尤其是一个bug在A的系统出现，却在自己的环境下无法复用。
2. 无法即刻搭建和线上同版本的环境，解决线上问题。小团队节奏很快，当前的工作目录可能和线上版本差几天的代码（diff可能已经是巨量），所以当线上出问题时，將工作环境切换过去非常耗时（尤其是数据库发生变化时）。
3. 为新员工构建开发环境耗时且问题重重。这和第一点有些类似，即在ubuntu下工作的构建开发环境的流程在osx下会break。尤其是后期我们不断有开发人员转换系统到osx下。

当时正好看到一篇关于 [vagrant](http://vagrantup.com) 的文章，感觉这正是我想要的救命稻草。

<!--more-->

## 理想的开发环境

我心目中理想的开发环境应该是这样子的：

* 编辑环境和运行/测试环境分离。这意味着开发人员，不管是dev还是ux，可以使用任何她喜欢的系统进行内容的编辑，而其产出可以无缝地运行在另一个统一的环境。无缝是很重要的体验，如果分离意味着在两个系统显示地频繁切换，那还不如不分离；在此基础上的统一的环境则让大家在同一个上下文中交流。
* 开发人员可以同时工作在好几个版本下。在途客圈，一个relase（或者一个scrum）以两周为周期，一周开发，一周测试，然后就上线，如图所示：
![tukeq iteration](/assets/files/charts/tukeq_iteration.jpg)<br/>
这意味着在任何一周，开发人员同时工作在3个不同的branch上，以week 3第一天为例：Dalian已经部署到线上，Edingburgh交付测试，而Florence正在开发中。开发人员能够无痛地在这三个环境中任意切换，就像任务调度一样，保存上下文，切换到另一个branch，开始工作。作为小团队，我们不希望甚至不可能将有限的人员切成三份来运作，所以应该通过工具支持这种开发状态。
* 能很好地支持持续集成。```travis-ci.org``` 跑跑开源项目还可以，但商业项目就免了，而且其每次构建都rebuild整套环境这个效率太低。

## 构建理想的开发环境

存在的问题和期望的解决方案已经摆出来了，接下来就是如何实现的问题。这种场景是典型的虚拟机大展拳脚的地方，VmWare会很欣慰地摆出VDI + vSphere的解决方案。不过小团队人少钱紧，自然只能寻找免费的替代品，即之前提到的 ```vagrant```。

### 什么是vagrant?

我对它的不太确切的理解是：一套自动化创建，部署和使用虚拟机的工具。```vagrant``` 原生支持 ```virtualbox```，这就足够了。通过一系列CLI命令，我们可以很方便地操作虚拟机。

* 创建并运行虚拟机：
    ```
    $ vagrant box add lucid32 http://files.vagrantup.com/lucid32.box
    $ vagrant init lucid32
    $ vagrant up
    ```
* 登入虚拟机：
    ```
    $ vagrant ssh
    ```
* 打包虚拟机：
    ```
    $ vagrant package --vagrantfile Vagrantfile.pkg
    ```

更详细的 ```vagrant``` 使用说明请参考其 [文档](http://docs-v1.vagrantup.com/v1/docs/getting-started/index.html)，这里就不详细介绍。

### 如何使用Vagrant构建理想的开发环境

在这个模型中，大家交流的基础是虚拟机。虚拟机随时被创建，随时又销毁，有一个box服务器 ```vagrant repo``` 来统一存储所有box并提供上传/下载服务。box服务器提供两类box：

* 基准box。每天半夜从github pull相应branch的代码，并辅以对应的database，自动打包成一个基准box。每个活跃的branch每天都会有一个新的基准box。基准box保存一周足矣。大家新的一天工作的基础是基准box。
* PR box。解决线上问题时，和QA，CI交流使用的box。

任意一个box都是一个沙箱，它包含和线上环境同版本的操作系统，运行环境。同时里面有对应branch的代码库和数据库。数据库采用线上数据库的一个子集，可以让系统正常运行即可。box和用户的host OS间可以共享目录，比如说代码的目录，这样可以让用户通过host OS上的个性化编辑环境撰写代码。此外，box里的port和host OS的port要能一一映射，这样用户完全具有本地的测试体验。

详细的环境和工作场景参见下图：

![dev environment](/assets/files/charts/environment.jpg)

### 适用场景

这样的开发环境能满足本地办公团队，甚至远程办公团队的需要。

* 同一个地点办公的团队，```vagrant repo``` 服务器可以放在本地，以获得最好的下载速度。
* 异地办公或者服务于开源项目的松散团队，可以把 ```bagrant repo``` 放在一个公网服务器，让参与者都能访问（安全性不在本文讨论）。访问速度的问题可以通过本地缓存来解决，这样在多人下载同一个box时会有近乎本地访问的体验。

## 免责声明

如引文所述，本文想法尚未来得及实践，所以不保证能正常运行，所以 "try it at your own risk"。笔者个人觉得这个想法的靠谱率在 90% 以上。

送上小宝的近照一张：

![小宝近期照片](/assets/files/photos/baby20130427.jpg)







