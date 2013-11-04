---
layout: post
title: Hatch: 实验
date: 2013-11-04 22:40
comments: true
tags: [tool, technology, hatch]
cover: /assets/files/posts/hatch_experiment.jpg
---

继续 [前文](/posts/2013-11-03-hatch-experiment.html) 。熬到了周末，正式开始了 ``hatch`` 项目的开发。首先是一个关键问题：如果每个文件的生成由一个单一的shell脚本完成，那么数据库打开/关闭的损耗会不会成为瓶颈？做了个简单的实验，发现每次打开都要花费0.2s，一个不小的数字。

```
➜  hatch git:(master) ✗ cat test.coffee
#!/usr/bin/env coffee

db = require('mongojs')('hatch')
col = db.collection('documents')

col.findOne {}, (err, doc) ->
    db.close()
```

```
➜  hatch git:(master) ✗ time ./test.coffee
./test.coffee  0.20s user 0.03s system 99% cpu 0.226 total
```

<!--more-->

这意味着照之前的设想，一千个文件如果都单独parse，那么仅数据库打开/关闭就需要200s，这是不可接受的。于是，最初的想法不得不调整。如果在一个大脚本中完成所有事情，显然是最经济的，但这样无法借助 ``makefile`` 的优势，于是妥协为：

1. 整个系统依旧由 ``make`` 驱动，除unix已有的工具外，撰写：``hatch-parse``，``hatch-gen``，``hatch-tag`` 和 ``hatch-index``。
2. 所有这些脚本支持 ``1..n`` 个参数，为输入的文件名。
3. 由于这样无法使用 ``makefile`` 中的依赖，所以需要一个 ``hatch-diff`` 为其提供参数。

解释一下第三点：

如果 ``hatch-gen`` 只处理单个文件，那么 ``makefile`` 中的依赖关系很容易推导出需要处理的文件，并依次处理之：
```
OUT=out
SRC=src
CONTENT_PATH=$(SRC)/contents
OUTS=$(subst $(SRC),$(OUT), $(shell find $(CONTENT_PATH) -type f -name '*'))

$(OUTS): $(OUT)%: $(SRC)%
    @echo "Creating $@."
    @$(HATCH_GEN) $@ $<
```

但如果我们要处理大批文件，则不能这么做，所以我做了个 ``hatch-diff`` 来返回更改过的文件列表，于是 ``makefile`` 变为：

```
generate:
    @$(HATCH_GEN) $(shell $(HATCH_DIFF) -e .html $(CONTENT_PATH) $(CONTENT_OUT_PATH))
```

> 注：写该代码时我还不知道 ``makefile`` 有 ``$?`` 这样的神器。所以其实 ``hatch-diff``基本没用。


## 具体实现

实现代码见：https://github.com/coderena/hatch.

核心代码在 ``lib/core.coffee``。目前实现得很简单，还没有进一步的命令行来帮助使用者创建项目。

测试代码在 ``test`` 下。

具体实现很简单，也很直接。就不讨论。

## 问题与解决

### 加速，加速，加速！

打开数据库的时间越滞后越好。

能通过 ``makefile`` 的 dependency 解决的就放在那里解决。数据库里的内容和磁盘上的文件谁新谁旧，可以通过建立这样的 dependency:

```
$(CONTENT_DEPS): $(DEP)/%: $(SRC)/%
    @touch $@

content_depend: $(CONTENT_DEP_PATHS) $(CONTENT_DEPS)

```
每次 parse 完磁盘文件就更新 dependency，这样一旦文件改变，make就能分析出要重新parse的文件。

牢记 ``nodejs`` 单线程的劣势，尽可能用asynchronous的库和代码。需要异步处理一堆事情，但要在所有处理完成后统一操作请使用 ``async`` 库。

为了提高速度，所有 ``jade`` 模板都预编译好，再和 ``locals`` 结合，生成html。

### 绑定，绑定，绑定！

跟 ``docpad`` 一样，我希望用户可以定制他们自己的helpers，在模板中使用。比如：

```
hatchConfig =
    layoutData:
        site:
            # default url of the site
            url: 'http://hatch-jade-example.com'
            # default time of the site
            title: 'Example website build with hatch'

            getTitle: ->

                if @document.title
                    "#{@document.title} | #{@site.title}"
                else
                    @site.title
```

然后在模板中可以直接访问：

```
extends common/default

block prepend title
  | #{ getTitle() }
```

如果直接把 ``layoutData`` 传给 ``jade`` 去编译，``this`` 并不存在，必然报错。所以需要为每个helper函数进行 ``this`` 的绑定，问题是，[怎么判断一个值是函数呢](http://stackoverflow.com/questions/5999998/how-can-i-check-if-a-javascript-variable-is-function-type)？这是 javascript 语言中的又一个坑。我的项目中使用了 ``lodash``，所以自然而然会使用 ``_.isFunction()``:

```
locals = {document: data}
_.extend locals, self.config.layoutData
    for own key, value of locals
        if _.isFunction value
            locals[key] = value.bind(locals)
```

### 处理teaser和长文的分页

teaser一般是文章的头一段，在索引页中方便用户领略文章的大致内容。目前大部分静态网站生成器都使用html comment，如 ``<!--more-->`` 来达到这一目的，这样做有点问题：如果teaser之前有标题，那么标题也被包含在teaser里，展示效果不好，于是我采用下述方法定义teaser。用户仅需要在想标记为teaser的地方前后进行标注即可，不限于文章的任何部分，灵活性很好。

```
# teaser notation in the document
regexTeaser: /<!--\s*teaser\s*-->\s*([\s\S]*?)\s*<!--\s*teaser\s*-->/i
```

长文的分页也是类似的想法。定义了 ``<!--page-->``：

```
# page notation in the document
regexPager: /<!--\s*page\s*-->/
```

可以这样来生成页面：

```
@adapter.findOne src: src, (err, doc) ->
    return cb(err) if err

    if doc
        generate_doc = (i, callback) ->
            data = {}
            _.extend data, doc
            data.content = doc.contents[i]
            delete data.contents

            locals = {document: data}
            _.extend locals, self.config.layoutData
            for own key, value of locals
                if _.isFunction value
                    locals[key] = value.bind(locals)
            html = self.layouts[doc.layout] locals
            if i is 0
                filename = "#{dst}.html"
            else
                filename = "#{dst}.#{i}.html"
            fs.writeFile filename, html, (err) ->
                callback err, filename

        async.map _.range(doc.contents.length), generate_doc, (err, data) ->
            cb err, data
```

### 在jade里处理回调

由于用户可以自定义helper，如果要访问数据库，理论上可以这样做：

```
getRelated: (tags, cb) ->
    @adapter.findTag tags: $in: tags, 10, (err, docs) ->
        return cb(err) if err

        # blablabla
```

但在 ``jade`` 中，helper是不允许回调的，所以，除了把数据库访问变成同步模式，这个现在貌似无解。

## 测试

在我的本地环境中，我创建了一个有1k+ ``markdown`` 源文件的项目，测试结果还不赖：

```
➜  hatch-jade-example git:(master) ✗ make fullclean
➜  hatch-jade-example git:(master) ✗ time make
Creating dependency paths .dep/layouts.
Creating dependency paths .dep/layouts/common.
Creating dependency paths .dep/layouts/common/includes.
Creating dependency paths .dep/layouts/common/includes/asides.
Creating dependency paths .dep/layouts/common/mixins.
    Too many layouts changed, clean all outputs.
Parsing the documents into database.
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc  1118 docs parsed.
Creating output paths.
Creating output paths.
Creating output paths.
Creating output paths.
Creating output paths.
Creating output paths.
Creating output paths.
Creating output paths.
Creating output paths.
Creating output paths.
Creating output paths.
Creating output paths.
Creating output paths.
Creating output paths.
Creating output paths.
Creating output paths.
Creating output paths.
Creating output paths.
Creating output paths.
Creating output paths.
Creating output paths.
Creating output paths.
Creating output paths.
Creating output paths.
Creating output paths.
Creating output paths.
Creating output paths.
Generate documents.
    1118 docs generated.
Creating dependency paths .dep/contents.
Creating dependency paths .dep/contents/docs.
Creating dependency paths .dep/contents/post1.
Creating dependency paths .dep/contents/post10.
Creating dependency paths .dep/contents/post11.
Creating dependency paths .dep/contents/post12.
Creating dependency paths .dep/contents/post13.
Creating dependency paths .dep/contents/post14.
Creating dependency paths .dep/contents/post15.
Creating dependency paths .dep/contents/post16.
Creating dependency paths .dep/contents/post17.
Creating dependency paths .dep/contents/post18.
Creating dependency paths .dep/contents/post19.
Creating dependency paths .dep/contents/post2.
Creating dependency paths .dep/contents/post20.
Creating dependency paths .dep/contents/post21.
Creating dependency paths .dep/contents/post22.
Creating dependency paths .dep/contents/post23.
Creating dependency paths .dep/contents/post24.
Creating dependency paths .dep/contents/post25.
Creating dependency paths .dep/contents/post3.
Creating dependency paths .dep/contents/post4.
Creating dependency paths .dep/contents/post5.
Creating dependency paths .dep/contents/post6.
Creating dependency paths .dep/contents/post7.
Creating dependency paths .dep/contents/post8.
Creating dependency paths .dep/contents/post9.
Build completed!
make  5.93s user 1.65s system 100% cpu 7.540 total
➜  hatch-jade-example git:(master) ✗ touch src/contents/docs/2013-01-01-atanasoff-implementation.markdown
➜  hatch-jade-example git:(master) ✗ time make
Parsing the documents into database.
u   1 docs parsed.
Generate documents.
    1 docs generated.
Build completed!
make  2.28s user 0.24s system 101% cpu 2.477 total
```


## 后记 & 未完待续

这个项目目前仅仅实现了POC，比我预期的进展要缓慢一些。但这毕竟是我第一次跳出 ``express`` 的框框去写 ``nodejs`` 代码，所以可以原谅。

写 ``makefile`` 是种享受，尤其是几行很直观的代码下来就达到用编程语言几十甚至上百行的效果。不信，看看项目中我为了实现类似查找 dependency 变化的代码：

```
$ cat lib/diff.coffee
fs = require 'fs'
file = require 'file'
path = require 'path'
async = require 'async'
_ = require 'lodash'

# params should contain src, dst and ext
diffPath = (src, dst, ext, callback) ->
    fileTimeDiff = (src_file, cb) ->
        old_ext = path.extname(src_file)
        dst_file = src_file.replace(src, dst)
        if ext
            dst_file = dst_file.replace(old_ext, ext)

        fs.stat src_file, (err, src_stat) ->
            return cb(err) if err

            fs.exists dst_file, (exists) ->
                return cb null, src_file if not exists

                fs.stat dst_file, (err, dst_stat) ->
                    cb(err) if err

                    if src_stat.mtime > dst_stat.mtime
                        cb null, src_file
                    else
                        cb null, null


    file.walk src, (err, dirPath, dirs, files) ->
        async.map files, fileTimeDiff, (err, results) ->
            callback err, _.compact(results)

module.exports.diffPath = diffPath

$ cat scripts/hatch-diff.coffee
#!/usr/bin/env coffee
diffPath = require('./../lib/diff').diffPath

argv = require('optimist')
    .usage('''
           Compare two folders
           Usage: $0 [--ext html] src_dir dst_dir
           ''')
    .demand(2)
    .alias('e', 'ext')
    .describe('e', 'destination file extention')
    .argv


[src, dst] = argv._
ext = argv.e

diffPath src, dst, ext, (err, data) ->
    for item in data
        console.log item

```

这么复杂的逻辑仅仅实现了 ``makefile`` 中 ``$?`` 的功能而已。。。

送上小宝照片一枚。

![小宝](/assets/files/photos/baby20131103.jpg)
