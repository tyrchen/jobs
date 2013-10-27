---
layout: post
theme: default
title: Teamspark及Meteor杂谈
date: 2013-02-04 0:20
comments: true
tags: [meteor, teamspark, tool, product]
cover: /assets/files/posts/teamspark.jpg
---

我终于厚着脸皮把Teamspark开源了。

Teamspark是我做的一个协作软件。有关Teamspark的功能和使用方式见：[http://tchen.me/teamspark/](http://tchen.me/teamspark/)。或者你也可以直接clone或fork [Teamspark的github项目](http://github.com/tyrchen/teamspark/)。如果你想了解些关于Teamspark和Meteor的八卦，请继续阅读。

<!--more-->

## 杂谈/八卦

使用 [Meteor](http://Meteor.com) 撰写Teamspark一晃已两个多月。仍然记得当初因太兴奋，挑灯夜战浑然不觉的场景。那时白天为途客圈的Cayman项目奋斗，晚上为Teamspark殚精竭虑。没别的原因，就是手头使用的协作工具中有太多太多的问题，而我们亟需一个靠谱好用的协作工具。

Teamspark并不是我用Meteor的第一个项目。第一个项目是 [途客圈正字系统](http://github.com/tyrchen/zhengzi)，用来“惩罚”犯了小错的团队成员。比如说写代码犯二。惩罚的方式是给全员买雪糕。正字系统可以保存犯错和惩罚的历史，立此存照，达到警示作用（结果我的正字最多）。在写正字系统的过程中，我认识到了Meteor的威力：50行简单易懂的javascript就构成了正字系统的雏形。

在正字系统上尝到了甜头，我开始深入学习Meteor。正字系统诞生的时代还是Meteor 0.3.8的时代，那时只有很基本的权限管理，没有auth。所以当时尽管很火，Meteor还是只能用来写toy，想做个严肃的系统，对吾住，实现用户系统先！

在社区里强大的呼声下，Meteor的开发者开始也意识到了这点。于是一个貌似是叫auth的branch被创建出来，然后是相当active的development。好一阵我都在这个branch上厮混，不断尝鲜。当Meteor team announce auth功能基本可用后，我开始了我的teamspark之旅。

一周左右的业余开发，我做出了Teamspark的第一个版本。这是个MVP（Minimal Viarable Product）。仅仅包含以下功能：

* 创建project
* 创建和编辑spark
* 评论和赞同spark
* 按时间顺序浏览自己的spark和整个团队的spark（这对了解整个团队其他人干什么很有帮助）

我把它介绍给我的团队，并利用我产品经理的特权，尝试强制大家使用。不过对Teamspark的使用效果，我开始并没有太大的信心。因为之前Redmine在team里被推行了大半年，最终也没获得编辑运营团队的认可，很多关于产品的沟通还是基于email。

> Lessons learned 1: 
>
> __一切团队协作软件的最大竞争对手不是其他团队协作软件，而是email。__

言归正传。很快我得到了正面的反馈：大家都说好用。但光说是没有用的，用户确实在使用才是王道。我默默关注着Teamspark上spark（一个spark可以是一个idea, task, bug, feature, etc.）被创建的数量，这才是黑猫白猫面前的那只耗子。很快地，sparks的数量破10，接着又很快破了50，100。最可喜的是，编辑和运营团队在其中的贡献达到了一半以上。各种各样的产品idea被激发出来，比以前通过email交流提高了至少一个量级。

更有意思的是，我把Teamspark本身的管理和交流也放在Teamspark中。大家很快就贡献了不少想法，提交了很多bug。产品如果能够为自身的需要服务，那是再好不过的事情。比如说途客圈2.0的帮助，FAQ等信息也以笔记本的方式发布和呈现。

> Lessons learned 2:
> 
> __产品能服务自身的需求，能让team成员主动Eat your own dog shit，这是产品成功的内部保证。__

有了用户的支持，我自然动力大些。于是，根据反馈和需求，我先后做了如下功能：

* filter。当spark激增的时候，用户需要能看特定范围的spark。比如说三天内到期的，xxx发布的，优先级4以上的等等。
* sort。同上。需要除了按创建时间排序外，还能按优先级，更新时间等排序
* 文件和图片上传。这样设计稿等产品文档需要大家的comment时就不需要来来回回发邮件了。
* 用户激励。每个团队成员都能看到别人的积分（贡献）。积分主要以发表/完成数计算出。虽然一个团队内这么做有点多余，但是这个功能一上线后立刻在开发团队中引起了热捧：大家卯足劲就想让自己能够排在积分榜的前列。
  > Lessons learned 3：
  > 
  > __日常工作中有很多激发大家潜能的机会，关键看你做不做，及怎么做。__
* 标签。可以给每一个spark打标签。系统会为每个project记录用户打过的标签。如果说project是强制的spark分类工具，tag就是一个非常灵活的组织spark的工具。
* 搜索。直到spark的数量已经达好几百，内容的查找确实成为一个很大的瓶颈后我才开始做搜索。搜索是instant search，匹配部分或全部的任意如下内容：
  1. spark ID
  1. spark title
  1. spark tags

在做Teamspark的过程中，基本上在不断走build-measure-learn的loop。收获不少。

## Open Source or SaaS

在team内部得到某种认同后，我开始考虑Teamspark的商业化。在某天上班的路上，我用Evernote记录了当时的一些商业化想法：

* 用户可申请加入一个team，也可等待管理员批准其成为team成员。免费team人数上限5人，可以建最多10个项目。再往上就提供类似github这样的分级收费制度。
* 对于team，可以看到team简介，团队成员，以及管理员发布的最新动态。
* 用户登入后可看到自己加入的团队，及最近访问的ream。进入到某个团队后，状态会保留直至用户退出该团队。
* 使用全新设计的UI。
* 为project和spark提供丰富的模版。
* spark的内容markdown化（这样可以支持各种模版的渲染，及更好支持代码highlight）。
* Inview加载以获取更好的速度。
* 更好的performance
  * 不Publish team列表
  * 仅Publish自己至少有读权限的项目
  * 仅Publish分配给自己的spark

但将Teamspark做成一个SaaS的服务不仅仅这么简单。需要考虑这些问题：

1. Meteor还在0.5.x版本。离1.0似乎还有很长的路要走。将服务构建在一个并不稳定且没有经过大规模使用的framework下，对用户不负责。
1. 有很多安全问题待解决。最低的标准是一切数据皆需通过HTTPS传输。想想你公司内部的项目机密信息在不安全的信道上传输，是不是不寒而栗？像途客圈这样的非电商的toC业务对安全性的容忍度会高些，但Teamspark这样toB的业务对安全性是零容忍。因为一旦信息泄漏，对客户也许就是一场灾难。

所以思来想去觉得现在还不是一个正确的将Teamspark商业化的点。

如果不商业化，那就开源。对我而言，一个项目闭源又不商业化，只有一种可能：代码写得实在太矬且产品毫无价值。Teamspark虽然写得比较矬，但还是有点价值的。

但是，做个有人用的开源项目不是件简单的事儿，要花费很多额外的功夫：

* 项目的简易安装部署。我个人的经验是：安装部署麻烦，UI不好的开源项目，最容易被枪毙。
* 项目的帮助文档。起码要给用户一个顺利使用的guide。
* 找到合适的marketing channel。这年头，开源软件要冒尖，好看易用还远远不够，要找到合适的渠道去推销自己。对于teamspark，我决定尝试在hacker news上做marketing。
* 持续更新，不断改进产品。一个停止更新的项目不会或者很难获取到新用户。

尽管有以上种种额外工作，考虑再三，我还是决定把Teamspark开源。希望这对我而言是个好的开始。过去的几年间，我对开源社区的索取甚多，所写的的系统从头到脚都闪耀着开源软件的光芒。没有开源软件，我恐怕做不出来哪怕任何一个简单的web app。

## 后记

今早去医院看病（我的右手已经麻了一月有余，颈椎病），所以就啰啰嗦嗦写了以上这一堆废话。跟电脑打交道的亲们，平时要多注意保养自己的肩颈和双手，不要久坐，多外出活动。否则像我这样整天抬不起胳膊，半边肩酸疼，一只手几乎全麻，滋味很不好受。

还是放上小宝一张照片：

![小宝照片](/assets/files/photos/baby20130204.jpg)







