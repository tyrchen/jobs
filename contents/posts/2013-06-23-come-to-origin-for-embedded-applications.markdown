---
template: post.jade
theme: default
title: Come to Origins for Embedded Applications
date: 2013-06-23 08:14
comments: true
tags: [architecture]
---

## The problem

Recently I did a web application to make easy GNATS report for my team. I use scrapy to crawl the GNATS web pages for people's issues every 4 hours, then add the crawled data into mongodb. A set of simple-to-use RESTful APIs written with nodejs can provide easy access to the data ([try it out](http://api.jcnrd.us/gnats/tchen.json), but only viewable internally in Juniper). Then a django application consumes the APIs and wraps them into a not-so-bad user interface, thanks to twitter bootstrap and a set of javascript frameworks and libraries. You can look at the ultimate application here: [GNATS report system](http://gnats.jcnrd.us/groups/branch-team/).

What I want to emphosize is, I did all these stuffs in less than a full week, and then a working edition is there. I've not counted the code, maybe a few thousands line of python, coffescript, css and html code.

Here comes the problem - I can never be so productive when writing code for the datapath of JUNOS, or any embedded systems I've been working with. Why is it?

<!--more-->

Then I began to compare the differences for my web application and the data path application, say NAT for embedded systems, to find the magic.

### Web application

* Almost all the software is running at user mode. Even the most mission critical, throughput sensitive applications, like DBMS, web server, are working in user mode.
* Great frameworks there for you to achieve your goal. They have really nice layering with separation of concerns beared in mind. You don't need to know the details about the underlying layers, just focus what your application is required to do.
* There're good conventions for you to follow, so that even the not so experienced engineer can write good-quality, working code.
* You can for sure scale up, and it is not that difficult to scale out.

### Applications for embedded systems

* Usually your code is running in kernel mode (especially the data path code), even if it is not required to.
* No good framework and people who're working on architecture may be not aware of how important a good framework means to the applications.
* No separation of concerns. As a developer, you need to master the complexity of the whole system to write correct code, even if for not so underlying application like NAT, you have to care about locking, CPU, session, etc., which, in my opinion, should not be exposed to you.
* No good convention to follow so that people tend to write code in a very different style and even very bad code (long switch case with duplicated code everywhere).
* Scale up is not so easy, scale out is a disaster.

Yes you can argue the embedded systems are much more complicated, but making not so complicated things complex is much easier than making it simple, right? If you think about a whole web systems, you need to deal with web server, db server, message queue server, cache server, etc., and each of them expose every detail to you and you have to learn all of them, who can write web applications so easy?

You may also argue that performance is everything so we had to sacreface almost everything. But is it really the right way of doing it, considering the hardware is getting a lot better and better than 15 years ago? 15 years ago, web applications are also written in C or equivalent, in terms of performance I guess? But what about now? Our mind should change with the era. Furthermore, is it easier to write the architecture right firstly then optimize it afterwards? Or it is easier to optmize the application firstly even if making a lots of things in a mess then evolve the whole mess? The answer is transparent.

So here's my point - let's try to make the architecture right with a framework with usability for developer bear in mind.

## The solution

Here I'll try to come out a crazy data plane framework. I don't even know if it works but it is a good stress test for your brian when you're in a 12-hour flight with nothing else to do.

### Engine

Engine is a very light-weight component like thread, but the memory footprint is much less and there's no data copy between engines. To boost the performance, multiple instance of the same engine could be run simutaneously.

Engine is the minimum unit in the forwarding path, following **open-close** principle. An engine should do and only do one thing, it usually should not be changed when introducing a new feature. For example, you should not create a l3 forward engine which combined lots of stuffs in it. Instead, you should do something like a TTL engine, which just decrease the TTL of the given packet.

An engine have an inqueue and outqueue to hold packet to be processed and to be sent to the next engine. The writer of the engine usually isn't aware of it. To move packet forward to the next engine, current engine just need to call API like this:

```
return next_engine();
```

This API will automatically calculate the next-to-call engine, and distribute to one of the not-so-busy instances of the engine.

To write an engine, you basically need:

1. UI/Configuration. Write a erlang script to subclass ``Command`` and implement methods like ``set``, ``get``, ``debug``. Configuration is stored into memory based key-value database.
2. Main logic. Subclass ``Engine`` and implement ``c2s(pkt)`` and ``s2c(pkt)``. They will be called by ``process(pkt)`` based on the traffic direction.
3. Insert engine into the right place of the global engine database.

### Path

Path is a set of engines that packet will go through. Usually the first packet packet will trigger a session installation, which creates bidirection paths for the session.

Path is organized as bitmap.

The ``next_engine()`` API will work with path to decide the next engine, but the engine owner doesn't need to deal with path.

### Session

Session is almost the same concept as what a typical firewall session is. It's 5-tuple based, bi-direction data structure that provides enough information for engines to process packets.

Sessions are stored in a memory based key-value database. It can be queried and modified by database API.

After session lookup, each packet data structure will have a copy of the matched session. Except invalidation, normally engines should not modify sessions in database. Only session lookup engine could modify session - e.g. the sequence number, the statistics info, etc.

There are two session classes: ``SessionStore``, ``Session``.

``SessionStore`` has the static ``match`` method, if you inherit ``SessionStore``, ``get_key()`` and ``modify_on_match()`` should be implemented. 

``SessionStore`` will be separated based on protocols.

``Session`` has ``execute()``, which will call the engine path attached to the direction that packet comes.


### Tunnel

``TunnelSessionStore`` inherits ``SessionStore``. ``TunnelSession`` inherits ``Session``.

``TunnelEngine`` inherits ``Engine``, which ``c2s()`` calls ``encap(pkt)``, ``s2c()`` calls ``decap(pkt)``. So you need to implement ``encap()`` and ``decap()``.

## The next step

There are much more to consider, for example, TCP Proxy, ALG, IDP, AI, QoS, etc. But unfortunately my flight is almost over and I need to release my brian for something more relex.

DPDkit can zero-copy the packet from driver to user space. This is a great news for this idea.

I'm struggling for a while about the langyages I should choose. To me, golang is too young, python/ruby is too simple, and c/c++ is just naive to do it. Erlang, on the contrary, seems to be a smart choice for it.

I know little about erlang. You can see my previous psudo code are all in c/python. I don't even know if erlang supports OOP (I guess so). What I think it is the right choice is because:

* string concatenation is O(1), which is rooted in its language essense of erlang. Think about fragmentation and reassemble you'll see how efficient it is.
* Processes are really, really light-weighted to spawn tens of thousands in a shot.
* You have no chance to mess things up through shared memory. The only way for communication is messaging, which is quite efficient without copying (hope my memory is correct).
* Erlang has its own key value realtime database called mnesia which could be used as configuration or even session stores (hopefully it is better than berkeley DB).

So the next step is to learn erlang, and to try to write a framework, which by adding an engine, I can make the basic pass-through TCP traffic work without any issue.

Don't laugh at me if you're expert. It is not an architecture spec. I just let my thought fly and record it faithfully.

<!--

这不是说做web application要比做embedded system简单得多，而是一种思维方式和做事方法上的不同。我们做个简单的比较：

### Internet application

* 所有依赖的软件几乎都运行在user mode。
* 你可以用很多的工具和框架来达到目的。你可以用nodejs和mongodb来提供api和数据的持久化；用django提供view和controller；bootstrap实现前端展现。所有这些基础结构都开源且运行良好。
* 良好的层次划分和Separation of Concerns让你从不用担心死锁，也不用去考虑这段代码运行在哪个CPU上，你只需知道只要我遵循相应的convention，就能写出质量不错，能正常工作的代码。
* 可以scale up，也比较容易scale out。

### Application for embedded system

* 很多时候不需要运行在kernel mode的代码被运行到了kernel mode。
* 没有现成的framework（或者即使有，也没有人愿用）。
* 没有separation of concerns。作为一个开发者，你需要对整个系统的复杂度了解得非常透彻，即使做NAT这样相对不那么复杂的应用，你也不得不关心锁，CPU，session这些本不需要暴露给你的东西。
* 没有convention可言，每个人写出来的代码都有不同的风格。


-->