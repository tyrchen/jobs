---
layout: post
title: 尝试github "Zen Writing Mode"
date: 2013-01-25 08:38
comments: true
tags: [github]
---

## Zen Writing

最新的 [hacker news](http://news.ycombinator.com) 有个 [链接](https://github.com/blog/1379-zen-writing-mode) 关于Zen Writing Mode，看完后迫不及待地尝试用它写自己的博客。感觉还是挺不错的。

和使用sublime + markdown插件的方式撰写文章比起来，用Github Zen Writing Mode有以下几个优点：

* 任何时刻，任何机器，只要能访问互联网，就能写作。
* 界面很清新，无干扰，专注于写作本身

缺点：

* 无语法高亮显式，如 __强调__ 并未给我视觉上的反馈
* 列表元素无法自动生成，懒散如我最不愿意多敲哪怕一个* （这个甚至不如原来的编辑器）
* 离开网络无法使用

不管怎么说，以后多了个写作的工具，总归是好事。不过Github要是能把自己原来的编辑器的优点放入Zen Writing Mode，一定会有更多人使用。

![Github Zen Writing Mode](/assets/img/snapshots/zenwriting.jpg)

<!--more-->

## 实现
程序猿的老毛病又犯了，忍不住打开source code，看看从前端代码能否找到些许可用的open source library的端倪。可惜，Github似乎没有用诸如 **AceEditor**，**EpicEditor** 这样的工具，是自己写的。但其实这样的mode用 [EpicEditor](http://oscargodson.github.com/EpicEditor/) 并不困难。至于语法高亮和自动生成列表元素，似乎也并非难事，不知Github为何不做。KISS？

## 意外收获
看当前页面source code时，发现一句有意思的引用：
```
<script type="text/javascript" 
  async="" id="gauges-tracker" data-site-id="4f5634b5613f5d0429000010" 
  src="https://secure.gaug.es/track.js">
</script>
```

Github竟然在使用 [gaug.es](http://get.gaug.es/) 这样一个我之前未听说过的tracking system，实在令人惊奇。不过多年的代码生涯，我秉持两个凡是：

* 凡是Github上被star/fork多的项目，都是值得学习的好项目
* 凡是Github引用的代码或使用的服务，都是好东西
 
看了下gaug.es的介绍，感觉不错，但realtime/live data早就不是新鲜玩意儿，mixpanel, chartbeat等一票analytics tools都是realtime，gaug.es有何出众？不管怎样，有Github背书，先记下这个网站，以后慢慢研究。

## 后记

虽说这是篇酱油文，但小宝的照片还是不能不放：
![小宝](/assets/img/photos/baby20130124.jpg)
