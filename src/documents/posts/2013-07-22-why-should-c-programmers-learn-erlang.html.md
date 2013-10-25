---
layout: post
theme: default
title: Why should C programmers learn Erlang?
date: 2013-07-22 18:32
comments: true
tags: [functional, erlang]
---

## Prologue

If somebody says X language is better than Y language, usually there will be a fierce quarrel between two sides. If you're using certain language for a long time, you will be the evangelist of that language, and try to protect it unconsciously. Admitted or not, you have been trapped in a tunnel, that what you can see is constraint greatly. "The Shawshank Redemption" gives a good footnote on it:

![institutionalized](/assets/img/snapshots/institutionalized.jpg)

> [Red] These walls are funny. First you hate 'em, then you get used to 'em. Enough time passes, you get so you depend on them. That's institutionalized.

So before we're institutionalized too deep, let's learn something completely different - a language that not derived from C family, a language that leads you to a totally different mindset.

Erlang seems to be a good candidate.

## Why Erlang?

Erlang is a languages more than 20 years old, developed initially by Ericsson, for the purpose of their "next-gen" switch. It's a really weird language with "clumsy" grammar which mixed with the functional programming into Prolog. However it adopts almost the best design philosophy, which is still ahead of the current era at least 10 years. Let me show you gradually.

### No side effects (almost)

As a functional programming language, Erlang eliminates the shared states. Variables can only be bound to, but not changed. 

```
1> X = 1.
1
2> X = X + 1.
** exception error: no match of right hand side value 2
3> X = 2.
** exception error: no match of right hand side value 2
```

This makes sure that you can write functions that has no side effects - which means, with the same parameters, even if you call the function a thousand times the return value is the same. Writing code that has no side effects is a fundamental advantage in Erlang, it has these benefits:

* There's (almost) no critical sections you need to protect. Think of C code under concurrent environment, you have to use various synchronous primitives to prevent data from corruption. Poor synchronization leads to poor performance and instability of the system. This is a great headache for C programmers.
* It makes low level optimization easier. The compiler can aggressively optimize the register usage since it knows once a variable is set it will not be changed.
* It makes garbage collection easier. Think of poor Java VM. To determine if a variable is garbage or not is not a easy thing since it might be reference by others, and it might be used or changed later. But Erlang not. A variable is only in the scope of the outer function. Nobody else will use it. Nobody will change it. (read more about [Erlang garbage collection](http://stackoverflow.com/questions/10221907/garbage-collection-and-memory-management-in-erlang) if you're interested).


### Asynchronous / Concurrent built in language

Erlang has built-in support of concurrent / asynchronous in its language. The theory backed Erlang's idea is [Actor Model](http://en.wikipedia.org/wiki/Actor_model). This is a great vision in 1986 since at that time multi-core, multi-thread, or even SMP is not a known terminology.

#### Light weighted process

To support concurrent, Erlang has its own light weighted process on its VM. You can spawn tens of thousands of processes simultaneously without hitting the limitation of the OS. Furthermore, the creation of the processes are super-fast - [350,000Hz for an old Pentium 4 CPU](http://www.lshift.net/blog/2006/09/10/how-fast-can-Erlang-create-processes). The memory footprint of Erlang process is quite small - in the granularity of kilobytes (minimum ~300 bytes), rather than megabytes for OS level processes. As for scheduler, Erlang support soft realtime scheduler, and the cost of context switch is very low - [Switching between processes, takes about 16 instructions and 20 nanoseconds on a modern processor](http://stackoverflow.com/questions/2708033/technically-why-is-processes-in-Erlang-more-efficient-than-os-threads). If you're interested in scheduling, read [how Erlang does scheduling](http://jlouisramblings.blogspot.com/2013/01/how-Erlang-does-scheduling.html).

#### Message passing

Erlang use message passing for inter process communication, which inherits the idea of Actor model. Each process has its own mailbox to hold messages that cannot be processed immediately.

With built-in process and message passing between processes, Erlang made itself full asynchronous.

#### Example

```
-module(echo_server).
-export([rpc/2, loop/0]).

rpc(Pid, Request) ->
    Pid ! {self(), Request},
    receive
        Response ->
            Response
    end.

loop() ->
    receive
        {From, {message, Message}} ->
            From ! {ok, Message},
            loop();
        {From, Request} ->
            From ! {error, Request},
            loop()
    end.

%% in shell:

1> c(echo_server).
{ok,echo_server}
2>  Pid = spawn(fun echo_server:loop/0).
<0.42.0>
3> echo_server:rpc(Pid, {message, "Hello world!"}).
{ok,"Hello world!"}
4> echo_server:rpc(Pid, {message1, "Hello world!"}).
{error,{message1,"Hello world!"}}
```

Hope you're not overwhelmed by the grammar and the details on functional programming. I'm not going to go into details of this code - it basically create a echo server then send message to the echo server. By using ``spawn``, ``!`` (keyword for message passing) and ``receive`` we created echo server with only several lines of code. Think about how you achieve this by using C, Java, Python, Ruby or node.js. You will find the beauty of Erlang.

As actor model is so important to the concurrent world, modern languages like Golang support it in the language level as well. I'm not familiar with Golang, but as it does allow you share memory, doing concurrent in Golang may still need synchronous primitives. Furthermore, I don't think Golang support software real-time since this is the goal of Erlang but not the goal for Golang.

For other languages, such as Java, Python and Ruby, who supports Actor model in the form of the library, I doubt its efficiency. Only putting coroutine and it's scheduler in the VM level, you can get the maximum performance.

### Scale out

From previous example we can see that you're more likely to write loosely coupled applications in Erlang. With the built-in concurrency support, Erlang application is fairly easy to scale out. You can distribute your code from one node to multiple nodes, to different machines in same LAN, or even to servers in the other side of Internet, with only a little extra coding cost. This is because:

1. Erlang allows you to spawn process in a remote node.
2. Erlang allows you to interact with remote process, just like what you do for local process.

With a little change of previous program (added a new function), we can distribute it in two different Erlang nodes:

```
start() -> register(?MODULE, spawn(fun loop/0)).
```

```
➜  Erlang-programming-examples  erl -sname weasley
Erlang R16B (erts-5.10.1) [source] [64-bit] [smp:8:8] [async-threads:10] [hipe] [kernel-poll:false] [dtrace]

Eshell V5.10.1  (abort with ^G)
(weasley@cnrd-tchen-mbp)1> c(echo_server).
{ok,echo_server}
(weasley@cnrd-tchen-mbp)2> echo_server:start().
true

➜  Erlang-programming-examples  erl -sname potter
Erlang R16B (erts-5.10.1) [source] [64-bit] [smp:8:8] [async-threads:10] [hipe] [kernel-poll:false] [dtrace]

Eshell V5.10.1  (abort with ^G)
(potter@cnrd-tchen-mbp)1> rpc:call('weasley@cnrd-tchen-mbp', echo_server, rpc, [{message, "Hurry up, Harry!"}]).
{ok,"Hurry up, Harry!"}
```

### Hot code reload 

This is really a dream feature every system programmer wants. Think about all kinds of tedious hot patching solutions you provided to your customer. It's about hacking, dirtiness and limitations. But Erlang, on the contrary, supports hot code reload in an elegant manner.

Still use the echo server as an example, let's revise the code so that we could swap the code later:

```
-module(echo_server_general).
-export([start/2, rpc/2, swap_code/2]).

start(Name, Mod) ->
    register(Name, spawn(fun() -> loop(Name, Mod) end)).

swap_code(Name, Mod) ->
    rpc(Name, {swap_code, Mod}).

rpc(Name, Request) ->
    Name ! {self(), Request},
    receive
        {Name, Response} -> Response
    end.

loop(Name, Mod) ->
    receive
        {From, {swap_code, NewMod}} ->
            From ! {Name, ack},
            loop(Name, NewMod);
        {From, Request} ->
            Response  = Mod:handle(Request),
            From ! {Name, Response},
            loop(Name, Mod)
    end.

-module(echo_server).
-export([echo/2, handle/1]).

echo(Name, Message) -> echo_server_general:rpc(Name, {echo, Message}).

handle({echo, Message}) -> {ok, Message}.

%% shell output

(weasley@cnrd-tchen-mbp)1> echo_server_general:start(s, echo_server).
true
(weasley@cnrd-tchen-mbp)2> echo_server:echo(s, "hello world").
{ok,"hello world"}
```

Now the new requirement comes - our echo_server need to capitalize the first letter of the message and echo it back. Normally we need to shutdown the server, replace it with the new code, then restart the server again. You don't need to do so in Erlang.

```
%% revised echo_server.erl
-module(echo_server).
-export([echo/2, handle/1]).

echo(Name, Message) -> echo_server_general:rpc(Name, {echo, Message}).

handle({echo, Message}) -> {ok, capfirst(Message)}.

capfirst([H|T]) when H >= $a, H =< $z ->
    [H + ($A - $a)|T];
capfirst(Others) -> Others.

%% shell output
(weasley@cnrd-tchen-mbp)4> c(echo_server).
{ok,echo_server}
(weasley@cnrd-tchen-mbp)5> echo_server_general:swap_code(s, echo_server).
ack
(weasley@cnrd-tchen-mbp)6> echo_server:echo(s, "hello world").
{ok,"Hello world"}
```

Hot code reload is greatly useful not only for high availability of running software, but also very useful for software development life cycle. You don't need to waste lots of time to shutdown, load, and boot a big system for verifying a few lines of change.

I read several articles which claim hot code reload is not so useful in real world. People fears about the chaos of module versions of the hot reloaded software. Understandable. People tend to fear about unknown, and things that beyond their knowledge and vision. The power of the hot code reload will be discovered a decade later, when there's corresponding software management tools and theory appears. Erlang is too ahead its time that after more than 20 years its philosophy is still ahead of time.

### Fault Tolerance

The industry dreams on nine nines (99.9999999%) of system availability. However, software is made by people. People will make mistakes. Murphy's law says anything can go wrong will go wrong. So we can not avoid mistakes. Instead of getting us out of mistakes, a more important question is: how could our software survive with all kinds of mistakes?

Other languages train people to use defensive programming to try to protect your software from crash, but Erlang's philosophy is "let it crash". Why?

If someone built a house for you that as long as one of the window breaks the house will fall completely, will you stay in the house? Absolutely no. You need a house that you can still live in it though window is broken. You can later ask expert to fix it.

This is the difference between applications written in C and in Erlang. Crash is not a serious problem if you know how to recover from the crash. In Erlang: 

* a process crashing will not impact unrelated processes.
* crashed process will notify the processes linked to it.
* supervisor could be used to recover from the crash, e.g. restart the crashed process.

### Speed

the performance of Erlang code has some drawbacks compared with C:

* the code runs on top of VM
* runtime type deduction
* pattern matching
* ...

So how slow is Erlang? Inspired by this [post](http://stackoverflow.com/questions/6964392/speed-comparison-with-project-euler-c-vs-python-vs-Erlang-vs-haskell), I did the following tests in my mbp:

```
➜  comparison  time ./euler12.bin
842161320
./euler12.bin  5.90s user 0.01s system 99% cpu 5.910 total
➜  comparison  time erl -noshell -s euler12 solve
842161320
erl -noshell -s euler12 solve  11.09s user 0.19s system 100% cpu 11.269 total
➜  comparison  time pypy euler12.py
842161320
pypy euler12.py  9.92s user 0.05s system 96% cpu 10.305 total
➜  comparison  time ./euler12.py
842161320
./euler12.py  66.32s user 0.04s system 99% cpu 1:06.43 total
```

We can see that C code is almost 2x faster than Erlang. This is not bad for Erlang, considering the benefits it brings. Think about a I/O intensive situation. Think about concurrent or distributed situation. Erlang wins for sure.

Sooner or later one DIE will have a thousand cores. Even if nowadays Erlang cannot excel in performance, it will in future.

### Adoption

There are quite a few famous software built with Erlang:

* [couchDB](http://couchdb.apache.org/). A NoSQL database. 
* [RabbitMQ](http://www.rabbitmq.com/). A distributed message queue system.
* [ejabberd](http://www.ejabberd.im/). An instant message server.
* [AXD301 ATM switch](http://www.adelcogroup.com/EricssonAXD301.htm). Probably the only system in this planet reached nine nines. It hasn't been shutdown for 20 years.
* And a lot more companies, including Amazon, Facebook, Yahoo!, T-Mobile, use Erlang in their systems, see [Where is Erlang used and why?](http://stackoverflow.com/questions/1636455/where-is-Erlang-used-and-why)

## How to learn Erlang?

Erlang is really difficult to learn. But once you mastered it, you're the king. I like the words from Evan Miller, the creator of Erlang Web MVC framwork [Chicago Boss](http://www.chicagoboss.org/), in a good article named [Joy of erlang](http://www.evanmiller.org/joy-of-erlang.html):

> In the movie Avatar, there's this big badass bird-brained pterodactyl thing called a Toruk that the main character must learn to ride in order to regain the trust of the blue people. As a general rule, Toruks do not like to be ridden, but if you fight one, subdue it, and then link your Blue Man ponytail to the Toruk's ptero-tail, you get to own the thing for life. Owning a Toruk is awesome; it's like owning a flying car you can control with your mind, which comes in handy when battling large chemical companies, impressing future colleagues, or delivering a pizza. But learning to ride a Toruk is dangerous, and very few people succeed.

![toruk](/assets/img/snapshots/toruk.jpg)

It reflects perfectly how hard I learned Erlang. BTW, I've far from conquering it. 

Before learning Erlang, I have good master of C, Python and Javascript, programmed a little bit on C++, Java and Ruby. You can see my brain is filled with [Imperative programming](http://en.wikipedia.org/wiki/Imperative_programming). So the biggest challenges for me is to get used to functional programming, which implies __mind change__.

### No state change for variables

Variables can only be bound to but not changed. Suddenly I found I could not program.

For example, to implement upper(str) without using any helper function, such as map().

In Python, it's super easy and pretty straight forward:

```
def upper(str):
    str1 = ''
    for c in str:
        str1 += c.upper()
    return str1
```

But in erlang, without changing the internal state, how can I achieve it?

The ingredient is accumulator. Bear this paradigm in mind when writing Erlang code. The code looks like this:

```
upper(S) ->
    upper(S, []).

upper([], N) ->
    lists:reverse(N);
upper([H|T], N) when H > $a, H =< $z ->
    upper(T, [H + ($A - $a)|N]);
upper([H|T], N) ->
    upper(T, [H|N]).
```

The function itself doesn't have any internal state change, but we have achieved the same goal by having an accumulator passed as a parameter. This is a fundamental paradigm in functional programming world. __Master it or die__.

### Pattern matching

Pattern matching makes Erlang program beautiful and easy to understand. In C, a function is unique inside its scope. You cannot define a ``fun(x)`` firstly, then define ``fun(x, y)`` later. But in Erlang, there's no such limitation. You could define as many as functions as long as their parameters are different, you could also define as many as [clauses](http://www.erlang.org/doc/reference_manual/functions.html) for a function as long as their patterns are different. Take the above ``upper()`` function as an example. You call ``upper("#hello")``:

* as there's only one parameter, the call matches with ``upper(S)``, so we call ``upper("#hello", [])``.
* For ``upper("#hello", [])``, as "#hello" cannot match [], and the first char "#" doesn't match with the guard condition, the call matched ``upper([H|T], N)``, so it calls ``upper("hello", [$#])``.
* The following calls all matched with ``upper([H|T], N) when H > $a, H =< $z``, and it will change the char to uppercase. So the call sequence is:
```
upper("ello", [$H, $#])
upper("llo", [$E, $H, $#])
upper("lo", [$L, $E, $H, $#])
upper("o", [$L, $L, $E, $H, $#])
upper([], [$O, $L, $L, $E, $H, $#])
```
* for ``upper([], [$O, $L, $L, $E, $H, $#])``, it matches ``upper([], N)``, ``lists:reverse(N)`` is returned.

Pattern matching allows you to break your code logic into pieces, as a result, the body of each clause of a function is much smaller and more readable. That's why usually you see a C function is more than a hundred lines of code but an Erlang function clause usually takes no more than twenty lines of code.

Note that the sequence of the clauses are important. Erlang executes the first matched clause.

### The magic of recursive

When studying C programming, I was trained that recursion is a poison that you should use as little as possible. But in functional programming world, recursion is another fundamental paradigm.

Look back into the code I've written in this article so far. Do you see regular loop? No. But how about recursive function? Everywhere. Recursion replaces for/while loop, making a clean iteration or looping solution. Why? Think about the for loop in C. It involves with state change - for every step you change the iterating factor until it match the exiting criteria. But Erlang doesn't allow internal state change, so it uses recursion to replace normal for/while loop.

But you have doubts.

#### The performance of recursion is poor

This is a pseudo-proposition. 

Let me give you an example. The common sense is that passing parameters by registers is much faster than by stack. Intel CPU relies on stack push/pop so much for function calls since it has fewer general purpose registers than RISC CPUs. To boost performance it introduces the register stack so that push/pop operation is lightening-y fast - as fast as using registers.

Let's come back to recursion. We use little recursion in C, according to 80/20 principle, there's no immediate need to optimize it, right? But for Erlang, recursion is the lifeline of the code. How dare the compiler not to optimize it? So your intuition is wrong - recursion is not necessarily slow. Yes it is slow in C, but very fast in Erlang. 

#### It usually leads to stack overflow

Not exactly if you program in a right way. Erlang optimize the stack specially for [tail recursion](https://en.wikipedia.org/wiki/Tail_call). Let me give you an example:

```
fac(1) -> 1;
fac(N) when N > 0 -> N * fac(N-1).
```

This is not a tail recursion since the stack must be kept for calculation.

Let's make it a tail recursion one:

```
fac1(N) -> fac1(N, 1).

fac1(1, M) -> M;
fac1(N, M) when N > 0 -> fac1(N-1, N * M).
```

Each time a function call is made we can safely drop the stack of the last call, this is tail recursion.

The benefit of tail recursion is that you need only to keep a very small, constant memory footprint for recursion. So there's no worry about stack overflow for long running recursive programs.

In Erlang, you should program the code with tail recursion as long as it is possible.

### Functional programming in mind

Pay attention to the data that could be recursively accessed, such as list (including string). List could be processed like this:

```
retrieve([H|T]) -> {H, T}.

%% or even
retrieve1([H1, H2|T]) -> {H1, H2, T}
```

Bear map/reduce in mind.

Focus on algorithm, think how you achieve it with math formula. Then it should be easy to write it down with Erlang. Divide and conquer your problem. Do not get into details.

Let's take atoi(S) as an example.

The formula:
```

         |- S[0] is '-':  -1 * atoi(s[1:], 0)
atoi(S) -+
         |- else:         atoi(S, 0)

              |- S is []:       Acc
atoi(S, Acc) -+- S[X] is digit: atoi(S[X+1:], 10 * Acc + digit(S))
              |- else:          Acc
```

Thus we could write code like this:

```
-module(math).
-export([atoi/1]).

atoi([$-|S]) ->
    -1 * atoi(S, 0);
atoi(S) ->
    atoi(S, 0).

atoi([], Acc) -> Acc;
atoi([H|T], Acc) when H >= $0, H =< $9 ->
    atoi(T, 10 * Acc + (H - $0));
atoi(_S, Acc) -> Acc.
```

Think of how you write C code for ``atoi()``. The Erlang program is close to what your algorithm is. You can make it correct almost on your first try.


### Embrace processes

Process is not hard to use if you're willing to use it. It helps organize your system in a loosely coupled and asynchronous way. You just need to get used to it. Treat process as worker, as object, or anything you could analog.

### Let it fail

For C programmer, normally you should write code that covers every possible value of the parameters. But Erlang not. Take this example:

```
%% good code
fac(N) when is_integer(N), N > 0 -> fac(N, 1).

fac(1, Acc) -> Acc;
fac(N, Acc) -> fac(N-1, Acc * N).

%% bad code
fac(N) when is_integer(N), N > 0 -> fac(N, 1).
fac(N)                           -> {error, "argument must be positive integer"}

fac(1, Acc) -> Acc;
fac(N, Acc) -> fac(N-1, Acc * N).

```

Execute the good code with bad parameter will cause exception, like the following:

```
1> c(math).
{ok,math}
2> math:fac(10).
3628800
3> math:fac(-10).
** exception error: no function clause matching math:fac(-10) (math.erl, line 14)
```

Should we write code to process the negative integer? YES in C, NO in Erlang. The bade code saves the process from exception but it leads unnecessary handling for the caller. Caller needs to add extra code to handle this pointless return value, which only makes the system more complicated. Let the exception happen. Let the process crash. Handle exception only in the place that need to handle it.

## Materials to learn Erlang

Congratulations! After reading this long article now it's your turn to conquer your Toruk. Here's your weapon:

1. __Joe Armstrong__'s book __"Programming Erlang - software for a concurrent world"__. The best way to learn a language is to read the book of the language's father. I highly recommend you to read this book thoroughly, especially the chapters regarding with sequential programming, concurrent programming and OTP.
2. [Erlang doc](http://www.erlang.org/doc/). Read on when you have doubts.
3. Implement in Erlang for the problems you're facing in day-to-day work. For example:
    * Count the words for a given file.
    * Implement cloc (giving a directory, count the lines of code for different languages).
    * Write a message server that keeps top N unread messages in memory while keeping the rest in mnesia.
    * Write a markdown interpreter.
    * Write a web framework based on mochiweb.
    * Write a L3/L4 firewall that handles symmetric NAT translation (to focus on the problem itself you should use the data from tcpdump).
4. Read open source software, such as ranch, cowboy, boss_db, etc.

Hope you have fun!
