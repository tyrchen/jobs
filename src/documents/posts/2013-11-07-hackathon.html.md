---
layout: post
title: Hackathon官网
date: 2013-11-07 22:40
comments: true
ignored: true
tags: [tool, technology, hackathon]
cover: /assets/files/posts/hackathon.jpg
---

距2011年参加Techrunch Disrupt Beijing的Hackathon已经两年有余，之后由于种种原因，再无参加类似活动的经历。喜闻公司内部要举办Hackathon，连忙报名。可报名的页面也太矬了，参与者要在一个丑陋的表格上增增减减，没有激动人心的官方主页，没有报名团队和项目的激情介绍，甚至我怀疑获奖页面也一样矬，这一点都不符合Hacker的品味和精神。于是我就想在github上找个靠谱的Hackathon网站源码，部署以供本届大会之用，没料到搜寻一圈下来，没看到一个合适的项目。于是便催生自己写一个的念头。

<!--more-->

如果为任意一个靠谱的互联网公司来做这个项目，那么最简单也是最富有hacker精神的便是随便一个静态网站生成器做一个git repo，做好必要的template，然后任何参与者可以将自己的参与项目，团队介绍写在一个markdown文档中，提交，然后git hooks自动为其生成新的页面。

但这对参与者，尤其是Hackathon组织者的要求比较高，所以这是个备选方案。

我想做的是个全功能的hackathon官网，能够承担发起Hackathon，团队/项目注册，项目提交，确定demo日程，评选等主要功能。

## 产品概要

### 首页

Hackathon的landing page，介绍Hackathon，并展示最新的Hackathon活动。

### Hackathon

Hackathon只能由特殊权限用户（比如隶属于hackathon-creator group的用户）发起。发起者须填写Hackathon名称和模板，才能创建Hackathon。创建好hackathon后，用户可以在所见即所得的界面内编辑和修改Hackathon内容。

编辑完成并发布后的Hackathon页面任何人都可以访问。包含以下功能：

* 项目注册
* 倒计时
* 项目一览
* 最新消息

UI:

* ``/hackathon/create/``: 填写要创建的Hackathon的名字，选择对应的模板。
* ``/kackathon/:slug/edit/``: 编辑对应的Hackathon。
* ``/hackathon/:slug/``: 浏览对应的Hackathon。
* ``/hackathon/:slug/news/create/``: 创建一条新消息。

API:

* ``POST /api/v1/hackathon/``: 创建一个Hackathon。
* ``PUT /api/v1/hackathon/:slug/``: 修改对应的Hackathon。
* ``POST /api/v1/hackathon/:slug/news/``: 创建一条新消息。

### 项目注册

在Hackathon页面上，有一个项目注册按钮供那些有想法的个人和团队注册。项目分 ``idea`` 和 ``project``:

* Project：我将组建一个团队在Hackathon上实现我的想法。
* Idea：我有一个想法，任何感兴趣的团队可以把这个想法拿走在Hackathon上实现。

点击后进入到所见即所得的项目编辑页面。

UI:

* ``/hackathon/:slug/project/register``: 注册一个项目。填写项目名称，项目类型和模板，进入到下一步。
* ``/project/:id/edit/``: 编辑对应的项目。
* ``/project/:id/``: 浏览对应的项目。
* ``/project/:id/news/create/``: 创建一条项目消息。

API:

* ``POST /api/v1/project/``: 创建一个项目。
* ``PUT /api/vi/project/:id/``: 修改一个项目。
* ``POST /api/v1/project/:id/news/``: 创建一条项目消息。


