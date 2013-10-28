---
layout: post
title: 觅珠人：浴火重生
date: 2013-10-28 7:40
comments: true
tags: [docpad, technology, github]
cover: /assets/files/posts/reborn.jpg
---

很久没有更新博客了。最近几个月写了三篇文章：

* 8月底：『软件公司如何有效地组织和运作?』
* 9月中：『班加罗尔初体验』
* 10月：『nodejs callback hell的解决之道』
 
因为种种原因都烂尾，没有继续下去，所以也就没有发表出来。绵绵不断的工作压力和为人父的家庭责任让我心力交瘁，眼一睁一闭，一睁一闭的，一天天就过去了。

这两天闲逛hn时，无意中发现了 ``docpad``，又一个静态网站生成器。由于我目前使用的 ``wintersmith`` 是一个hack版，将其升级到2.x太麻烦，而且随着我文章的增多，分页，标签管理等都成为麻烦事。在尝试了 ``docpad`` 后，我发现这是个好东西，干脆心一横，就把整个博客的底层系统升级过去了。

<!--more-->

看过我之前博文的童鞋可能注意到，我的博客自诞生起，历经 ``wordpress`` -> ``octopress`` -> ``wintersmith`` -> ``docpad``。原因很简单，我需要一款能够支持以下功能的静态网站生成工具：

* 能使用 ``markdown`` 或任何其他语言撰写文章（posts）。
* 支持尽可能多的模板，如jade，haml。
* 能生成标签索引页。
* 能生成文章索引页。
* 索引页支持分页。
* 支持local server，能在本地展示生成出来的网站的感觉。
* 生成速度尽可能快（不要超过10s），并且不要做无意义的重复生成。
* 是CMS，而非blog engine。

在这个过程中，我不断寻觅，不断更新工具，直到我找到了 ``docpad``。除去对性能的要求外，``docpad`` 满足我上述所有需求。

所以我便开始了艰难的升级之旅。由于本文非 ``docpad`` 入门文档，重点描述我升级遇到的问题，所以要学习 ``docpad`` 请移步：http://docpad.org。

## 模板

这次升级，UI全部重写。我放弃了bootstrap 2，选择了bootstrap 3，亦即意味着完全放弃了IE7，基本放弃了IE8。我的博客读者并不很多，在百度统计中，IE7/IE8占比不到15%（IE7及以下不到1%），所以对整体用户影响不太大。

UI的设计购买自wrapbootstrap，花四十美刀买了个multiple license，很划算。如果从设计做起，我未必能做出这样的设计，而且短期内不可能升级完成。

购买后前端的主要工作就是把html变成template。由于 ``docpad`` 对 ``eco`` 支持比较好，所以我花了些时间学习eco。

## 文档

文档的改动主要在文件名和metadata上。``docpad`` 借鉴了rails的pipeline，根据文件名判断该如何转化，比如：``test.css.less``，``eco`` 会先通过 ``eco`` 处理转换成 ``test.css.less``，再通过 ``lessc`` 转换成 ``test.css``。

metadata的转换主要是 ``wintersmith`` 和 ``docpad``的命名不同，比如：

```
---
template: default.jade
published: false
---
```

在 ``docpad`` 中需要转换为：

```
---
layout: default // default.html.eco
ignored: true
---
```

这都不是什么大问题。

## 分页

之前的博客不支持分页，在首页我塞了40篇文章。如果我的博客超过了40篇文章，那么之前的就无法被直接索引到。使用 ``docpad`` 后，只要安装 ``paged`` 插件，并按例子写一小段代码，就能完美支持分页：

```
$ docpad install paged
```

我写的支持分页的partial：

```
<% if @document.page.count > 1: %>
<ul class="paginator text-center">
    <!-- Previous Page Button -->
    <% unless @hasPrevPage(): %>
        <li class="disabled"><span>上一页</span></li>
    <% else: %>
        <li><a href="<%= @getPrevPage() %>">上一页</a></li>
    <% end %>

    <!-- Page Number Buttons -->
    <% for pageNumber in [0..@document.page.count-1]: %>
        <% if @document.page.number is pageNumber: %>
            <li class="active"><span><%= pageNumber + 1 %></span></li>
        <% else: %>
            <li><a href="<%= @getPageUrl(pageNumber) %>"><%= pageNumber + 1 %></a></li>
        <% end %>
    <% end %>

    <!-- Next Page Button -->
    <% unless @hasNextPage(): %>
        <li class="disabled"><span>下一页</span></li>
    <% else: %>
        <li><a href="<%= @getNextPage() %>">下一页</a></li>
    <% end %>
</ul>
<% end %>
```

## 标签

在 ``docpad`` 里支持标签很容易，安装两个plugin就好：

```
$ docpad install related
$ docpad install tagging
```

前者提供『相关文档』的功能，后者能生成类似 ``/tags/:tag`` 的索引页。

我们先看如何显示相关文档：

```
<div class="widget widget-cats">
  <h4 class="widget-title">
    相关文章
  </h4>
  <ul>
    <% if @document.relatedDocuments : %>
    <% for document in @document.relatedDocuments: %>
      <li><a href="<%= document.url %>"><%= document.title %></a></li>
    <% end %>
    <% else : %>
      <li><a>无</a></li>
    <% end %>
  </ul>
</div>
```

这样，只要文档中使用了 ``tags: [tag1, tag2]`` 这样的metadata，所有定义了 ``tag1`` 或 ``tag2`` 的文章就被聚合在此。

生成标签索引页也不难，只要做一个template：

```
---
layout: default
---
<div class="container">
    <h1>文章列表：『<%= @document.tag %>』</h1>
    <hr/>

    <ul>
    <% for doc in @getCollection('documents').findAll({tags: '$in': @document.tag}).toJSON(): %>
        <%- @partial('posts/post_loop_item', {item: doc}) %>
    <% end %>
    </ul>

</div>
```

显示效果如：http://tchen.me/tags/technology.html。

## 问题

``docpad`` 功能很强大，但其速度让人难以忍受。之前 ``wintersmith`` 生成全站只需要3s左右，``docpad`` 则要40s。而且

为了加快速度我做了很多尝试：

1. 使用standalone metadata。https://docpad.org/docs/meta-data。效果一般，很多地方不适用，而且在诸如app.css.less里加这么个东西很不伦不类。
2. 对静态文件使用raw plugin。效果不明显，我往raw目录中拷一个文件还会trigger regenerate。
3. 停用live-reload插件。我不希望加了一个回车，保存后就要话40s才能访问本地服务器。
4. 使用 ``docpad watch``，而不是 ``docpad run``，同时启动一个 ``python -m SimpleHTTPServer 8210``，来serve静态文件。这样，改动能够被重新生成，且生成时我还能浏览已有的页面。

但这些都不太理想。``docpad`` 蠢到我改一行less，整个网站就全部重编。你可想而知在迁移阶段我有多少时间耗费在等待中。

于是我把所有的静态文件都拿出来放在 ``src`` 外，不让 ``docpad`` 干蠢事。完全抛弃 ``raw`` 插件，我写了个几行的 ``Makefile`` 干这些事：

* 将less生成css，并使用yuicompressor压缩。
* 将js用yuicompressor压缩。
* 将整个 ``raw`` 目录rsync到 ``out`` 目录。

在 ``raw`` 目录下的Makefile如下：

```
CHECK=\033[32m✔\033[39m
DONE="\n${CHECK} Done.\n"
ECHO=echo
ROOT=assets

CSS_COMPRESSOR=lessc
JS_COMPRESSOR=yuicompressor
SYNC=rsync
CAT=cat
RM=rm

CSS_PATH=$(ROOT)/less
CSS_SOURCE=$(CSS_PATH)/app.less

JS_PATH=$(ROOT)/scripts
JS_PLUGIN_PATH=$(JS_PATH)/plugins
JS_SOURCE=$(JS_PLUGIN_PATH)/jquery.js $(JS_PLUGIN_PATH)/bootstrap.min.js $(JS_PLUGIN_PATH)/jquery.visible.min.js $(JS_PLUGIN_PATH)/jquery.isotope.min.js $(JS_PLUGIN_PATH)/jquery.knob.js $(JS_PLUGIN_PATH)/jquery.scrollUp.min.js $(JS_PLUGIN_PATH)/highlight.pack.js $(JS_PATH)/application.js

CSS_TARGET=$(ROOT)/css/app.min.css
JS_TARGET=$(ROOT)/js/app.min.js

SYNC_TARGET=../out


sync: $(CSS_TARGET) $(JS_TARGET)
    $(SYNC) -au --exclude $(CSS_PATH) --exclude $(JS_PATH) --exclude Makefile . $(SYNC_TARGET)
    @$(ECHO) $(DONE)

$(CSS_TARGET):
    $(CSS_COMPRESSOR) $(CSS_SOURCE) --yui-compress  > $(CSS_TARGET)

$(JS_TARGET):
    @$(CAT) $(JS_SOURCE) > tmp.js
    $(JS_COMPRESSOR) -o $(JS_TARGET) tmp.js
    @$(RM) tmp.js

clean:
    $(RM) -f $(CSS_TARGET) $(JS_TARGET)
```

在根目录下的Makefile如下：
```
generate:
    docpad generate
    @cd raw; make; cd ..

deploy:
    cd out; make; cd ../..

clean:
    cd raw; make clean; cd ../..
```

这样，css/js的改动和 ``docpad`` 完全没关系，``docpad`` 只需要帮我生成文档即可。这样下来，60%的修改都能够在1s内完成。剩下40%的修改，耗时稍微少了一些，可还要用三十多秒。没有本质差别。

## 部署

强烈不建议使用 ``ghpages`` 插件部署。我安装了这个插件，也使用了，但使用第二次的时候就将其卸载了。原因很简单：每次 ``git push -f`` 全部重新push，写这个plugin的作者之前没生成过大一些的网站吧？我的博客现在几十篇文章，不足百张图片，总共几十M的repo，每次都全部重新push要十多分钟，一天push十几次我还干不干活了？

所以还是自己解决部署问题吧：

```
$ rm -rf out
$ git clone <your repo url>
$ make deploy # 这个我已经做进了上文中的Makefile中
```

在要部署的repo中添加一个Makefile:

```
DATE=$(shell date)
CHECK=\033[32m✔\033[39m
DONE="\n${CHECK} Done.\n"

deploy:
    @echo "Deploy the blog to github pages."
    git add --all .
    git commit -a -m "Deploy to github pages on $(DATE)."
    git push
    @echo $(DONE)
```

也是简单之极。

## 心得

这次博客升级花费了我两个晚上和一个周日。按我晚上9点开工到12点，周日工作了至少6小时，总共耗时12+小时，耗资USD40。

``docpad`` 是个功能丰富的工具，值得试用，但要忍受极慢的编译速度。撰写者（尤其是plugin的撰写者）显然水平一般，不懂得用unix的设计哲学来设计这样工具。

在经历了这么多工具后，我有强烈的意愿写一个自己的静态网站生成器，来更好地支持我的需求。想法很简单：

1. 使用Makefile和现成的工具完成静态文件的处理。
2. 高度组件化 - 撰写小脚本来完成单一的功能。用Makefile粘合这些脚本。
3. 脚本解析的中间结果存储在redis/mongodb中，供其他附加功能使用，比如tagging/paging。
4. 任何一个工具可以对全站使用，也可对部分文件使用。
5. 尽可能并发处理，全站的生成速度控制在秒级。
6. 如果可以，提供development模式，动态生成当前访问的页面。


送上小宝近照一张。

![小宝](/assets/files/photos/baby20131028.jpg)





