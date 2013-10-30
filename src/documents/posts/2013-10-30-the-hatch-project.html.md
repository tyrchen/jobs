---
layout: post
title: Hatch: 又一个建站工具
date: 2013-10-30 7:40
comments: true
tags: [tool, technology, hatch]
cover: /assets/files/posts/hatch.jpg
---

在 [前文](/posts/2013-10-28-blog-reborn.html) 中，我尝试了 [docpad](http://docpad.org) 做为新的建站工具。``docpad`` 有很多优点，但最大的缺点是效率。在我看来，一个好的静态网站生成工具最好能在秒级处理成千上万文档，这样才能真正满足个人博客外的中等规模网站的需求。要做到这一点，工具必须将full build和incremental build区别开来。这样，即使一个full build要花几十秒甚至几分钟，incremental build还能控制在秒级。当用户修改某个文件时，incremental build能够保证用户有良好的体验 —— 无需等待，改动立即可见。而这一点，则恰恰是 ``docpad`` 所欠缺的。本文讲述的 ``hatch`` 项目将尝试在保留 ``docpad`` 的诸多优点外，通过更智能的build过程将编译速度尽最大可能提高。

<!--more-->

## 目标

``hatch`` 的目标是实现如下功能：
1. 支持任意模板类型。官方可仅支持 ``jade``，但用户可以轻松扩展。
2. 支持任意格式的源文件。官方可仅支持 ``markdown`` 和 ``jade``，但用户可以轻松扩展。
3. 支持复杂页面的生成，如标签聚合页面（docpad-plugin-tagging）和每个文档的相关文档（docpad-plugin-related）的功能。
4. 支持less/coffeescript，及compress。
5. 支持live preview。

## 工具选择

有了目标，我们需要选择合适的工具去完成目标。

在web时代，尽管 ``rake``，``jake``，``grunt`` 等等task runner大行其道，我还是偏爱 ``make``，因为它最能体现unix的哲学：

> write programs that do one thing and do it well.

比如说将less生成css并打包，然后上传到服务器上这样的工作：

```
CSS_SOURCE=$(CSS_PATH)/app.less
CSS_DEPS=$(shell find $(CSS_PATH) -type f -name '*.less')
CSS_TARGET=app.min.css
SYNC_TARGET=tchen@my-awesome-server.com:/homes/tchen/deployment/css

$(CSS_TARGET): $(CSS_DEPS)
    lessc $(CSS_SOURCE) --yui-compress  > $(CSS_TARGET)

sync: $(CSS_TARGET)
    rsync -au $(CSS_TARGET) $(SYNC_TARGET)
```

这段代码很简单，目标任务 ``sync`` 依赖于 ``$(CSS_TARGET)`` 的构建，而 ``$(CSS_TARGET)`` 依赖于 ``$(CSS_DEPS)`` 的构建。

使用 ``make`` 简单明了，且不会做任何无用功。比如说：

```
$ make sync
```

在第一次执行后，如果less文件没有修改（ctime没有改变），则不会做任何事就结束了，节省大量的重复劳动。

使用 ``make`` 加上合适的shell命令（如果特定功能的命令不存在，我们需要自己创建），我们就可以构建一套完整的编译系统，将 ``markdown`` 文件（或者其他类型的文件），经过一系列处理，生成 ``html``。

## 依赖处理

如前文所述，我们要解决的问题归化成一个如何构建合适的 ``makefile``，让源文件（如markdown）高效地（且正确地）编译成目标文件（如html）。而这其中的重点，则在如何处理依赖。

最简单的依赖处理莫过于一个文件发生改变，整个项目都会重新编译。正确性得以保证，但显然不高效。``docpad`` 采用这样的策略，以至于对css的改动会引发html的重编。很不科学，漫长的等待让我这样的用户很受伤。

所以我们要设定合理的依赖规则。


对于目标中我们想要实现的功能，5暂且放在一边，1/2/4很好实现。3是一个难点，需要两次build才能正确处理：
1. make parse。每个修改过的文档单独parse，中间结果保存在 ``mongodb`` 中，如果 ``tags`` 信息有改变，则删除对应的标签聚合页（会触发重新生成），及受影响的文档页面。
2. make generate。调用整个正式的生成过程，生成所有需要重新生成的页面。

![博客截图](/assets/files/posts/hatch_dep.jpg)

如上图，如果删除了标签 ``docpad`` ，并添加了标签 ``hatch``，那么 ``make parse`` 时会将该文档的最新内容保存在db里，删除 ``docpad`` 和 ``hatch`` 的标签聚合页面，删除已经生成的所有包含 ``docpad`` 和 ``hatch``标签的页面（包括自己），然后进入到第二阶段的页面生成。

## 系统结构

有了上面的思考，``hatch`` 的系统结构也就付出水面，整个系统围绕着 ``make`` 展开，尽可能使用已有的unix工具（sorry，为了保证小而美，windows不在这样一个系统的考虑之列）。如果没有合适的工具，则撰写之。

可以直接leverage的工具：

* lessc/sass，用于生成css。
* coffee，用于生成js。
* yuicompressor，用于compress css和js。
* jade，用于将jade template生成html。
* marked，用于将markdown文件生成html。
* js-yaml，用于parse metadata。

需要撰写的工具：

* hatch-parse，用于parse一个文档，将中间结果存入数据库中。例如：``hatch-parse test.md``。hatch-parse会根据扩展名自动使用相应的parser。
* hatch-gen，用于生成一个页面，生成过程中可能需要读取数据库。例如：``hatch-gen -o test.html test.md``，``hatch-gen -o index.html index.jade``。如果文章需要分页（定义了``<!--page-->``），则进行分页处理。
* tag-gen，用于生成标签索引页。例如：``tag-gen -o hatch.html -t tag.jade hatch``。将会查询数据库中标签是 ``hatch`` 的文档，将其写入hatch.html。如果 ``tag-gen -o <dir> -t tag.jade *``，将会生成所有标签索引。如果生成过程中需要分页，则进行分页。
* index-gen，用于生成索引页。例如：``index-gen -o index.html index.md``。如果生成过程中需要分页，则进行分页。

## 数据结构

我用过的 [wintersmith](http://wintersmith.io)，[docpad](http://docpad.org) 都使用memory db存放文档的中间结果，为特殊需求（如related documents）提供接口。由于采用 ``make`` 来组织整个系统，每个运行的命令都是自己的进程空间，所以无法用in process memory db，另外我也不希望每次build都重新生成这个DB，所以一个可以persistent的DB就是我的第一选择。考虑到我有如下需求：

* 数据库中的字段来源于文档的metadata，所以随意性很大，必须schemaless。
* 需要支持一些复杂的查询，比如，找出6篇标签为：``hatch`` 或 ``tool`` 的文档。

所以权衡之后，本文决定使用mongodb来保存中间结果。当然，每次build时可能涉及很多次数据库的open/close，至于performance如何，只有实测后才有结论。

mongodb中存储的是文档（template无须存储），大概长这个样子（``createdAt``，``tags``，``ignored``，``src`` 上建有索引）：

```
{
    "_id": ObjectId(`blablabla`),
    "template": "posts.jade",
    "createdAt": ISODate("2013-10-30T20:20.000Z"),
    "updatedAt": ISODate("2013-10-30T20:25.000Z"),
    "tags": ["hatch", "tool"],
    "ignored": true,
    "comments": true,
    "cover": "/assets/files/posts/hatch.jpg",
    "src": "/documents/posts/hatch.md",
    "outputs": ["/posts/hatch.html", "/posts/hatch.1.html"],
    "title": "Hello Hatch",
    "rawContent": "This is a great document\n\nHello hatch!\n",
    "teaser": "<p>This is a great document</p>",
    "content": "<p>This is a great document</p>\n<!--more-->\n<p>Hello hatch!<p>"
}
```

对应在磁盘上的文件是这个样子：

```
---
template: posts.jade
title: Hello Hatch
date: 2013-10-30 20:20
tags: [hatch, tool]
comments: true
ignored: true
cover: /assets/files/posts/hatch.jpg
---

This is a great document

Hello hatch!

```

这引入一个问题：当磁盘文件修改时，如何找到数据库中对应的文档？源文件名是少数不那么容易修改又具备唯一性的字段，所以在数据库文档中我们放入了 ``src`` 这个域。在 ``makefile`` 里，我们需要提供 ``make dbclean``，以便用户在需要时，可以将数据库中的文档清除干净。

## 实现

从构思的角度，基本的障碍已经消除，大致的设计也有了，剩下的就是如何实现。这个周末，争取能把最基本的功能实现出来，然后在讨论实现过程中遇到的问题，看看和我的构思/假设有什么明显的偏差。

这几天没怎么照相，还是送上之前照的一张照片：

![小宝快一岁了](/assets/files/photos/baby20131030.jpg)









<!--
* index-gen，用于生成索引页，比如说标签索引页，首页等。用户传入一个查询条件，和一个排序条件，从数据库中读取对应的数据，生成html。例如：index-gen -e '[{"q": {"tag": "hatch"}, "s": {"date": -1}, "name": "dataset1"}, ...]'  > hatch.html。

比如说我们要生成 ``index.html``。它通过 ``documents/index.md`` 和 ``templates/index.jade`` 生成，并能展示 ``documents/posts`` 和 ``documents/slides`` 目录下的最新10篇文章。
-->







