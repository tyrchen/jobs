---
layout: post
title: 为什么要使用wintersmith取代octopress
date: 2013-01-21 06:55
comments: true
tags: [octopress, wintersmith]
---

## 引言
使用octopress已经有一段时间，用这套framework构架博客，写作和部署感觉相当地爽。然而，就我个人的网站而言，我希望它不仅仅是一个博客系统，不光能产生固定格式的post/page，更应该是一个完整的CMS，能根据我个人的需要定制更多的内容展现方式。在使用octopress的这段时间，我尝试为其添加了对演示文档的支持，对更多模版的支持，但感觉还是有点别扭，就好像你让守门员去踢自由人，能干，但干不好。

我希望我的个人网站能够有以下特点：

1. 随时随地使用 ```markdown``` 来撰写文章
  * 文章可以是word, excel, ppt等类型
  * 可以像office那样选择想用的模版
  * focus在写作本身，而不是最终的展示
2. 生成静态页面，可以最小化部署（比如说直接用github pages）
3. 能够对内容做各种各样的聚合
  * 相同标签
  * 相同系列
4. 很方便添加模版
5. 能够保护私有内容

于是上周起，断断续续，我开启了对个人网站的升级之旅。

<!--more-->

## 选型
需求确定后，就是技术选型。能够实现这类需求的static site generator自 ```jekyll/octopress``` 始，已经有 [一大把](http://tuxlite.com/2012/02/static-site-generators-are-the-new-wordpress/)，比如说python世界里的 [Pelican](https://github.com/getpelican/pelican/)。因为最近在看nodejs，非常喜欢jade这个模版系统，所以想在nodejs领域中找找类似的framework。找到两个：

* [blacksmith](https://github.com/flatiron/blacksmith)：http://nodejitsu.com 的静态网站生成器，nodejitsu自己也在用。
* [wintersmith](https://github.com/jnordberg/wintersmith)：受blacksmith激发产生的一个静态网站生成器

blacksmith最大的问题是不支持jade做为模版引擎，且没有提供一些基本的命令如preview。所以最终我选择了wintersmith。

## Wintersmith

### 安装

```
$ npm install -g wintersmith
```

安装完成后可以看看它提供的基本命令：

```
$ wintersmith --help

usage: wintersmith [options] [command]

commands:

  build [options] - build a site
  preview [options] - run local webserver
  new <location> - create a new site

  also see [command] --help

global options:

  -v, --verbose   show debug information
  -q, --quiet     only output critical errors
  -V, --version   output version and exit
  -h, --help      show help
```

### 使用
我们先来创建一个新的系统，使用wintersmith内置的template。

```
$ wintersmith new myblog
  initializing new wintersmith site in ~/documents/myblog using template blog
  done!
```

然后使用 ```wintersmith preview``` 打开预览模式，通过浏览器访问 http://localhost:8080/ 就可以查看生成的效果。

wintersmith的template放在templates目录下，而和网站相关的一切资源，如：文章，css，js等都放在contents目录下。缺省的目录结构不太理想，我个人喜欢这样一个结构：
```
├── config.json                          site configuration and metadata
├── contents
│   ├── archive.md
│   ├── posts                   
│   │   └── 2013-01-22-this-is-a-post.md
│   ├── slides                           
│   │   ├── 2013-01-21-awesome-slides.md                   
│   │   └── the-wintersmith.json
│   ├── assets
│   │   ├── img
│   │   ├── css
│   │   └── js
│   ├── feed.json                        json page that renders the rss feed to feed.xml
│   ├── index.json
└── templates
    ├── layout
    │   ├── includes
    │   │   └── footer.jade
    │   ├── mixins
    │   │   └── header.jade
    │   └── layout1.jade
    ├── posts.jade
    └── ...
```

生成出来的网站和contents目录下的目录结构完全一样。

### 深入了解
在wintersmith的框架下，每一篇文章都可以有自己的一些metadata，用过octopress的人都知道，一篇文章长这个样子，用 `:` 隔开的内容就是metadata：

```
---
layout: post
title: 为什么要使用wintersmith取代octopress
date: 2013-01-21 06:55
comments: true
tags: [octopress, wintersmith]
---

## This is the subtitle of the post

This is the content of this post!
```

对于metadata，wintersmith会将其解析出来到 `page` 对象中。对于内置的metadata，可以直接访问，如page.title；对于自定义的metadata，可以通过metadata引用访问，如page.metadata.tags。

wintersmith内置的metadata：

Field      | Description
:----------|:--------------------------------
metadata   | the metadata object
title      | `metadata.title` or `Untitled`
date       | Date object from `metadata.date` if set or unix epoch time
rfc822date | a rfc-822 formatted string made from `date`
body       | unparsed markdown content
html       | parsed markdown content
intro      | the intro part of the content, before `more`

由于文章都是采用markdown语法撰写的，wintersmith使用 [marked](https://github.com/chjj/marked) 将其生成为html。marked是个相当不错的parser，performance很好，而且支持github对markdown语法的扩展，如：table，code block等。marked还使用 ```highlights.js``` 对代码的高亮做了很强的支持。

marked生成的html可以被page.html访问到。另外，如果你在文中定义了：

```
<span class="more"></span>
```

wintersmith会将这之前的内容放入page.intro中，方便在各种索引页面使用。

## 定制

### 撰写模版
使用wintersmith撰写模版是件很惬意的事情，因为它使用了jade。和jade相比，各种其他template system如jinja2，handlebars等都显得极其臃肿和复杂，写jade的时候我第一次感觉做页面不是件苦逼的差事。

我们先写个layout.jade练练手：

```
doctype 5
html
  head
    meta(charset="utf-8")
    meta(http-equiv="X-UA-Compatible", content="IE=edge,chrome=1")
    title
      block title
        = locals.title
    meta(name="description", content="")
    meta(name="viewport", content="width=device-width")
    //link(rel="stylesheet", href="/assets/css/bootstrap.min.css")
    //link(rel="stylesheet", href="/assets/css/font-awesome.css")
    //link(rel="stylesheet", href="/assets/css/base.css")
    //link(rel="stylesheet", href="/assets/css/red.css")
    link(rel="stylesheet", href="/assets/css/style.css")


    //if lt IE 9
      link(rel="stylesheet", href="/assets/css/font-awesome-ie7.css")
      script(src="/assets/js/html5-3.6-respond-1.1.0.min.js")

    block css

  body
    block header
      include mixins/nav
      +topnav(page.metadata.which)
    block content

    block footer
      include includes/footer

    block js
```

代码很简单，相信只要有html基础，哪怕第一次使用jade的人也能很快看懂。是不是有种比 `zencoding` 还爽的感觉？

有了基本的layout后，我们需要对文章，演示文档分别提供模版，我们就以演示文档为例。

### 支持reveal.js的模版

由于reveal.js的页面有自己独特的layout，所以我们不从layout.jade继承，而是直接写一个新的：

```
doctype 5
html
  head
    meta(charset="utf-8")
    title #{page.title} - #{locals.title}
    meta(name="apple-mobile-web-app-capable", content="yes")
    meta(name="apple-mobile-web-app-status-bar-style", content="black-translucent")
    link(rel="stylesheet", href="/assets/reveal/css/reveal.min.css")
    link(rel="stylesheet", href="/assets/reveal/css/theme/#{page.metadata.theme}.css", id="theme")
    link(rel="stylesheet", href="/assets/css/code/github.css")
    link(rel="stylesheet", href="/assets/css/style.css")
    
    // if lt IE 9
        script(src="/assets/reveal/lib/js/html5shiv.js")

  body.reveal
    .reveal
      .slides
        != page.html

      
      a.back(href="/pages/slides.html", title="返回")
        i.icon.icon-arrow-left
        | 演示文稿列表

    script(src="/assets/reveal/lib/js/head.min.js")
    script(src="/assets/reveal/js/reveal.min.js")
    script
      // Full list of configuration options available here:
      // https://github.com/hakimel/reveal.js#configuration
      Reveal.initialize({
        controls: true,
        progress: true,
        history: true,
        center: true,

        theme: Reveal.getQueryHash().theme, // available themes are in /css/theme
        transition: Reveal.getQueryHash().transition || '#{page.metadata.transition || 'default'}', // default/cube/page/concave/zoom/linear/none

        // Optional libraries used to extend on reveal.js
        dependencies: [
          { src: '/assets/reveal/plugin/classList.js', condition: function() { return !document.body.classList; } },
          { src: '/assets/reveal/plugin/markdown/showdown.js', condition: function() { return !!document.querySelector( '[data-markdown]' ); } },
          { src: '/assets/reveal/plugin/markdown/markdown.js', condition: function() { return !!document.querySelector( '[data-markdown]' ); } },
          { src: '/assets/reveal/plugin/highlight/highlight.js', async: true, callback: function() { hljs.initHighlightingOnLoad(); } },
          { src: '/assets/reveal/plugin/zoom-js/zoom.js', async: true, condition: function() { return !!document.body.classList; } },
          { src: '/assets/reveal/plugin/notes/notes.js', async: true, condition: function() { return !!document.body.classList; } }
          // { src: '/assets/reveal/plugin/remotes/remotes.js', async: true, condition: function() { return !!document.body.classList; } }
        ]
      });
    include layouts/includes/baidu_tongji

```

这个模版提供了reveal.js的骨架，其中：

```
!= page.html
```

这一句会把你的演示文档正文插入到当前位置。为了能够让文档可以自定义theme和transition，这里还使用了两个metadata：theme和transition。

有了这样一个模版，你只需要专注于文档的内容就好。举个例子（可以访问 [这里](/slides/my-first-slide.html) 看实际效果）：

```
---
layout: slide
title: 我的第一篇演示稿
date: 2012-12-26 20:50
theme: serif
---

    # 我的第一篇演示稿
    ### Brought to you by Tyr Chen
    Stay hungry, stay foolish.

    2012-12-26


    <!--more-->


    ## 目标

    * 能够使撰写slides脱离繁琐的power point or keynote
    * 使用__sublime__撰写演示稿
    * 能够在octopress里嵌入演示稿
    * 能够随时随地access和share


    ## slide可以嵌入

    ### 也可以提供各种标题
    #### 也可以提供各种标题
    ##### 也可以提供各种标题
    ###### 也可以提供各种标题


    ## THE END


```

注意这里我对marked做了一点修改（我实在想不到更好更简洁的语法，于是就把code的语法占用了-_-），为4个空格开头的内容生成 `<section></section>` 标签，这也是reveal.js需要的。具体代码就不列在这里，大家可以直接fork我的marked clone：https://github.com/tyrchen/marked。

## 后记

这项工程花了我不少时间，但改版后，相对于之前的octopress，无论从内容的生成速度上，代码的可读性上还是可扩展性上都提升了几个档次。下一步就是把一些第三方的组件，如多说，百度分享集成进来，提高互动性。

依然放上小宝的一张照片：

![小宝](/assets/files/photos/baby20130121.jpg)






