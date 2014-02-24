---
layout: post
title: 闲扯code review
date: 2014-02-24 22:00
comments: true
tags: [thoughts]
cover: /assets/files/posts/codereview.jpg
---

如果说git终于让工程师在合作撰写代码的过程中找回了丢失已久的乐趣，那么，code review的过程还是让人相当地抓狂。我用过的所有code review的工具，没有一款能让code review的过程轻松起来。

<!--more-->

公司内部使用的工具自不必说，那是反人类的极致体验。

reviewboard和gerrit不那么反人类，但submit review和review的流程也不太方便，而且体验并不一致。submit review可以在命令行下方便地完成，但review需要点开邮件通知里的链接才能查看。如果你一直在代码上工作，而不查邮件，你可能会miss掉一些review。

不过，这些体验上的问题都是细枝末节。目前已有的code review工具的最大问题是：__它不是写给程序员用的！__慢着，这话听着好耳熟？没错，Linux Tolvalds在撰写git的时候，就说svn最大的问题是这玩意儿不是写给程序员用的。

如果要我设计一款code review工具，它的使用体验会类似这样：

## Submit code review

```
$ git commit -a
$ git push
```

Done! 不需要更多的流程了。

这里面隐含了如下步骤：

* git commit时会弹出一个form，所有项目都正确填写才能提交。
* git push时会将diff push到review server上，review server会根据修改了那些文件确定出reviewers，然后从中round robin选两到三人进行review。

与之最接近的体验是gerrit:

```
$ git commit -a
$ git push origin HEAD:refs/for/master
```

但，``HEAD:refs/for/master``究竟是什么，我想没多少人能搞懂。如果配置了一个repo必须要经过code review后才能push到服务器，那么，为何不直接把``git push``用做review的命令？

## Review the code

蒂尔原则：code review应该和repo紧密相连，而不是那该死的邮件。

当reviewer在同样的repo下运行``git status``时，会有如下提示：

```
$ git status
# On branch master
nothing to commit, working directory clean
You have 2 reviews:
  6ae24fe: PR12345 - can not connect to server, by Tyr Chen
  723e9e2: PR12346 - Tracking feature 123: add queue support, by Tyr Chen
You must run "git review <review-id>" to do review. 
```

这个提示很恼人，一般git用户都会尽快完成review以便让``git status``的输出看上去干净些。如果review长时间得不到处理，其颜色每隔4个小时变红一些，直至鲜红。

Reviewer可以运行``git review``进行代码review：

```
$ git review 6ae24fe
```

根据配置，这条命令会自动调出对应的代码比较工具，比如说``vimdiff``。如果没有指定，则会输出标准的``git diff``。

代码阅读完毕，可以使用：

```
$ git review 6ae24fe --approve|reject
```

这会弹出一个form，填写review的意见。

被round robin出的2-3个reviewers必须全部approve，这个review才算通过。如果某个reviewer在72小时内还没有review代码（可能休假去了），则相应的review自动被approve，review的注释是："review skipped automatically due to XXX not-responding"。这就像信用记录，对于一个程序员来说，如果他review别人的代码总出现这样的日志，自己脸上也挂不住。

此外，review服务器还记录和索引每个review，方便日后检索。以后如果哪个问题是由某次不正确的修改导致的，那么能够很快查询到是谁批准了这段代码。

最后，review的数据最好能做visualization，每个程序员都能看到他的历史review图表（这个可以做得非常有意思），也可以看到各种各样的统计信息（比如说团队里提交代码的排行榜，review通过率排行榜，review大牛排行榜等等），让冷冰冰的code commit和code review活泼起来。

投票：如果有这样一个code review工具，你会试用么？回复即可。:)