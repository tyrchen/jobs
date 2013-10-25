---
layout: post
theme: default
title: 创业谈 - 创建办公环境
date: 2013-05-16 07:42
comments: true
published: false
tags: [startup]
---

公司发展到五个人以上，有两三个开发人员时，就要考虑构建一套高效的办公和开发环境。以下是笔者的一点经验。

## 域名

为你的公司注册至少两个域名，一个对外，提供公司的形象展示和产品服务；一个对内，做为内网办公之用。域名建议采用第三方的解析服务，如**dnspod** (下文的域名设置均以dnspod中设置为例)。

## 办公系统

在Google Apps对小企业免费前，这是唯一的选择。可惜现在每用户要$5每月，如果你觉得这笔钱花着不值当（主要是还得时时翻墙），可以考虑使用QQ企业邮箱，功能比gmail差了一个等级，但能凑合用，而且是完全免费的。

默认QQ企业邮箱的域名是exmail.qq.com，你可以在dnspod里把你的域名的mx记录指向``mxbiz1.qq.com.``及``mxbiz2.qq.com.``，
mail
CNAME
默认
exmail.qq.com.

