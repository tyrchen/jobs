---
layout: post
theme: default
title: a cure to nodejs callback hell
date: 2013-10-16 15:40
comments: true
tags: [node, javascript, generator]
---

很久没有更新博客了。8月底的一篇文章：『软件公司如何有效地组织和运作?』和9月的一篇文章『班加罗尔初体验』因为种种原因都烂尾，没有继续下去。绵绵不断的工作压力和为人父的家庭责任让我心力交瘁，眼一睁一闭，一睁一闭的，一天天就过去了。

这两个多月来，技术层面上最令我兴奋的事情莫过于generator在nodejs上的支持。nodejs是一套优秀的网络应用开发框架，javascript的异步执行特性让nodejs开发I/O密集型（如互联网产品）应用如鱼得水。然而成也萧何，败也萧何，异步执行最大的问题就是带来大量的回调函数嵌套（callback hell），代码可读性很差。现在，V8引擎终于在语言层面支持generator了，而nodejs的v0.11.x分支也支持最新的V8引擎，从而让我们有机会写出更漂亮的代码。

在谈论generator之前，我们先看看现有的解决办法。我们先看看标准的node代码是什么样子。为了让本文更贴近实际，下面的例子使用mongodb，首先请安装mongojs:

```
$ npm install mongojs
```

我们使用mongojs撰写一段创建用户的操作：

```
$ cat mongo_user.js
(function() {
    var userCreate = function(username) {
        var mongojs = require('mongojs');
        var db = mongojs('test');
        var users = db.collection('user');
        var query = {'username': username};
        users.find(query).limit(1, function(err, docs) {
            if (docs.length > 0) {
                // we'd like to update the user
                var user = docs[0];
                user['count'] += 1;
                users.update(query, {$inc: {count: 1}}, function(err) {
                    console.log('updated user ' + username + ': ' + user['count']);
                });
            } else {
                // we'd like to create the user
                users.save({'username': username, 'count': 1}, function(err) {
                    console.log('saved new user ' + username + ': 1');
                });
            }
        });
    }
    exports.userCreate = userCreate;
}).call(this);
```

代码很简单，如果用户不存在，创建之；如果存在，更新其count。

```
$ node
> var u = require('./mongo_user');
undefined
> u.userCreate('tchen');
undefined
> saved new user tchen: 1

undefined
> u.userCreate('tchen');
undefined
> updated user tchen: 2

undefined
> u.userCreate('tyr');
undefined
> saved new user tyr: 1

undefined
```

在 ``userCreate`` 中，我们的回调已经达到三层。如何能够减少回调的层次，让代码更清晰呢？


## fibers

fibers将coroutine引入node，让你可以撰写同步代码，同时享受异步的福利。

```
$ npm install fibers
```

注意撰写本文时，fibers（v1.0.1）不能在v0.11.x的node上编译通过，如果你已经装了这个版本的node，请回滚到v0.10.x。

由于fibers提供的api偏底层，不建议直接使用。fibers本身做了一个future的封装，下例使用fibers的future封装。

```

```





## generator入门

首先我们需要nodejs v0.11.x的运行时，你需要从源代码编译安装。撰写本文时最新的版本是v0.11.7：

```
$ wget http://nodejs.org/dist/v0.11.7/node-v0.11.7.tar.gz
$ tar zxvf node-v0.11.7.tar.gz
$ cd node-v0.11.7
$ ./configure
$ make
$ make install (sudo if needed)
$ node -v
v0.11.7
```

首先我们尝试fabonacci:

```
$ cat fab.js
(function() {
    var fab = function*(n) {
        var a = 1, b = 1, c;
        do {
            c = a + b;
            a = b;
            b = c;
            yield c;
        } while (c < n);
    }
    exports.fab = fab;
}).call(this);
```

执行这个代码的时候需要注意使用 ``node --harmony``，不使用 ``harmony``，默认不识别 ``yield`` 关键字。看来V8/node也怕被和谐。:)

```
$ js  node --harmony
> var f = require('./fab');
undefined
> g = f.fab(10);
{}
> g.next();
{ value: 2, done: false }
> g.next();
{ value: 3, done: false }
> g.next();
{ value: 5, done: false }
> g.next();
{ value: 8, done: false }
> g.next();
{ value: 13, done: false }
> g.next();
{ value: undefined, done: true }
> g.next();
Error: Generator has already finished
    at GeneratorFunctionPrototype.next (native)
    at repl:1:3
    at REPLServer.defaultEval (repl.js:129:27)
    at REPLServer.b [as eval] (domain.js:251:18)
    at Interface.<anonymous> (repl.js:277:12)
    at Interface.EventEmitter.emit (events.js:103:17)
    at Interface._onLine (readline.js:194:10)
    at Interface._line (readline.js:523:8)
    at Interface._ttyWrite (readline.js:798:14)
    at ReadStream.onkeypress (readline.js:98:10)
```

这里的语法和其他支持generator的语言基本一致，只是每次调用的返回值是一个包含yield后表达式的结果和generator的状态。当generator返回 ``{done: true}`` 时，继续访问会抛出异常。

## 进一步探索

我们最终的目标是使用generator来摆脱无穷无尽的callback，那么

借助generator和Q，我们可以这样做：

```
$ npm install Q
```

```
$ cat mongo_user_q.js
(function() {
    var Q = require('Q');
    var userCreateQ = function(username) {
        var mongojs = require('mongojs');
        var users = mongojs('test').collection('user');
        var query = {'username': username};

        var db = {
            find: Q.nbind(users.find, users),
            update: Q.nbind(users.update, users),
            save: Q.nbind(users.save, users)
        };

        Q.async(function* () {
            docs = yield db.find(query);
            console.log(docs);
            if (docs.length > 0) {
                var user = docs[0];
                user['count'] += 1;
                var ret = yield db.update(query, {$inc: {count:1}});
                console.log('updated user ' + username + ': ' + user['count']);
            } else {
                var ret = db.save({'username': username, 'count': 1});
                console.log('saved new user ' + username + ': 1');

            }
        })().done();

    }
    exports.userCreateQ = userCreateQ;
}).call(this);
```
