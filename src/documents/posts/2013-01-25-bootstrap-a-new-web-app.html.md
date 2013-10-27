---
layout: post
theme: default
title: 后端工程师的逆袭：单枪匹马搭建一个新的Web App
date: 2013-01-25 14:13
comments: true
tags: [thought, startup]
---

## 引子

小T是个很苦逼的后端工程师。他拥有通天的本领，从web server到db，从cache server到MQ，从assembly到Javascript，写得了算法，玩得了数据，十八般武艺样样精通。可惜，他生在一个矮矬穷靠边站，高富帅是宇宙中心的时代。看人家的产品一个个长得娇艳欲滴，自己的却蓬头垢面，心里那个郁闷。每每朋友刚一试用，产品的美妙还未体现，就被痛快枪毙。睡梦中，小T不知道把发明GUI，让屏幕充满色彩的那些家伙干掉多少回了，也不知道憧憬过多少次没有色彩，没有图形，满屏幕都是字符的世界 —— 每个用户都像hacker一样通过清脆的键盘敲击，进入一个又一个自己创建的产品。

<!--more-->

可是梦总有醒的时候。打开窗户，外面是一片蓝天。

小T脑袋里又冒出一个新的产品想法，很小的想法，他迫不及待地在纸上构想，推演，一幅又一幅时而简单，时而复杂的草图在笔尖下跃出。

擦了擦鼻头的汗，看着草图，小T满意地笑了。这玩意能做。如果每天晚上9点到11点无干扰工作两个小时，一个包含主要逻辑的demo一周内就能做出来。Piece of cake! 

这种时刻，小T总是有一种舍我其谁的自负。

等等，__这些活怎么办__？

* 页面布局
* 配色风格
* 基本样式
* 全站的icons
* ...

小T惊出了一身冷汗。他深知在这些方面自己等同一个白痴，他曾经花了10分钟用gimp画了一个 `+` 的的图标，后来就配色和审美被师兄师弟，甚至路人甲鄙视了半年。

> * 我有审美能力，但我做不出来看上去美的东西。
> * 我不是色盲，但我的配色水准让我恨不得自己就是色盲。
> * ...

在一次SWOT分析中，小T在Weakness那一栏如是写到。

如果在这些方面没有改进，这个产品的命运可想而知，demo一出估计还会继续被毙。毕竟俺做的不是12306这样的刚需。

给前端的兄弟打了一通电话，结果他们不是在泡妞的路上，就是正在泡妞。WTF，女人真是容易被美丽的外表欺骗。他们做的那些玩意儿，离了我的API能跑起来么？小T不屑地啐了口吐沫。

鄙视归鄙视，小T只能无奈地自己一个人苦苦琢磨。该如何拯救你，我的想法？

恍惚中，小T误入了chrome神殿，google大神轻挥衣袖，把他带入open source的世界。

## 第一站：Bootstrap

[Bootstrap](http://twitter.github.com/bootstrap/) 提供几乎前端所需要的一切，由于名气很大，在此之上的project相当众多。小T收下后暗想：这货我以前用过几次，但从来都是浅尝辄止，这次痛下决心，要学好bootstrap。

![Bootstrap](/assets/files/snapshots/bootstrap.jpg)

## 第二站：SubtlePatterns

[SubtlePatterns](http://subtlepatterns.com/) 能够提供各种各样很有质感的页面的底纹。别小看这小小的底纹，用好了能让App增色不少。小T欣然收入囊中。

![Subtle Patterns](/assets/files/snapshots/subtlepatterns.jpg)

## 第三站：COLOURlovers

在 [COLOURlovers](http://www.colourlovers.com/browse) 的世界里，小T找到了天堂的感觉。原来非黑即白，大红大紫的世界里还有这样淡淡的美丽，就像其中一个调色盘的title所说那样：life is a gift。小T突然觉得有色彩的世界，很美好。

![Colour Lovers](/assets/files/snapshots/colourlovers.jpg)

## 第四站：Font Awesome

小T早对设计做的那堆css sprite不满了，稍微放大一些，各种狗啃般的锯齿就出来了，不想要锯齿，sprite要重新生成，多一倍的图标，大一倍还多。小T头脑中浮现出之前的sprite hell...

![Sprite Hell](/assets/files/snapshots/spritehell.jpg)

你看人家 [Font Awesome](http://fortawesome.github.com/Font-Awesome/) 的思想，多给力，一个小小的字体文件就搞定，还提供了bootstrap的支持，真棒！收之，必收之，有了示意性的图标，页面丰富多了，谁说俺做不好前端？那是俺没有利器～

![Font Awesome](/assets/files/snapshots/fontawesome.jpg)

临走前，发小广告的偷偷塞给小T一个链接：[Elusive Iconfont](http://aristath.github.com/elusive-iconfont/index.html)，小T看了看，觉得也挺靠谱。

迈出大门后，又一个小广告飞速冲过来，硬塞了个链接，说是build what you want only。小T打开一看，是 [Fontello](http://fontello.com/)。这是个好东东。

![Fontello](/assets/files/snapshots/fontello.jpg)

## 第五站：Bootstrap themes

手握各种利器，小T已经雄心万丈。这下来到了bootstrap themes的王国，心里的最后一块石头落地了。这些themes或者为我所用，或者为我所学，总之有了他们，做页面有底多了。小T自言自语到。

* [BootTheme](http://www.boottheme.com/#gallery)
* [BootsWatch](http://bootswatch.com/)
* [Wrapbootstrap](https://wrapbootstrap.com/)

![Wrap Bootstrap](/assets/files/snapshots/wrapbootstrap.jpg)

不过令小T不那么开心的是，Wrapbootstrap里面模版的效果很好，但要收费。狠了下心买了个admin模版，下次的项目前端基本有着落了。

## 第六站：Emoji

[Emoji](http://www.emoji-cheat-sheet.com/) 这货很好！小T眼前一亮，遂又黯淡下来，苦笑，google大神，你怎么最后给了我个打酱油的？我现在的项目肯定用不到。不过留着也好，说不定哪天加个feature，开个聊天室，各种表情就有用武之地了。

![Emoji](/assets/files/snapshots/emoji.jpg)

## 第七站：家

回到家中，小T拿着刚才获得的六件武器，开始**单枪匹马**打磨自己的新产品...

本故事纯属虚构

-----

## 后记

笑谈毕，依旧上小宝照片。

![小宝抬头](/assets/files/photos/baby20130125-1.jpg)

![小宝穿裙子](/assets/files/photos/baby20130125-2.jpg)


