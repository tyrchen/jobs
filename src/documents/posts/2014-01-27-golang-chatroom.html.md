---
layout: post
title: Golang之chan/goroutine
date: 2014-01-30 07:40
comments: true
tags: [script]
cover: /assets/files/posts/chatroom.jpg
---

最近在team内部培训golang，目标是看看golang能否被C工程师快速掌握。我定了个一个月，共计20小时的培训计划，首先花10个小时（两周，每天1小时）让大家掌握golang的基本要素，能写一些入门级的程序，之后再花两周时间做一个1000行代码规模的Proof of concept项目。为了能在培训的slides上直接运行go code，我做了个简单的 [coderunnerd](https://github.com/tyrchen/coderunnerd)，可以接受websocket传过来的code，编译运行再把stdout返回给websocket，为了更清晰地说明goroutine和chan的使用，以及golang的一些best practice，我分阶段写了个 [chatroom](https://github.com/tyrchen/chatroom)。本文介绍一下如何使用goroutine和chan来做一个简单的聊天室。

<!-- more -->

## 需求

聊天室的需求很简单：

* 服务器监听某个端口，客户端可连接并开始聊天。
* 任何客户端的发言都会被广播给所有客户端。
* 客户端可以为自己设定名字或者执行一些聊天命令。

## 设计与实现

### 基本想法

服务器（Server）：

* Server accept下来的connection被存在一个数据结构Client中，并以connection为key，Client为value，存在map里。
* 每个Client都有自己的goroutine去接受和发送消息。Client和Server之间通过channel来传递消息。

客户端（Client）：

* 发送和接收都有各自的goroutine，通过channel和stdin/stdout交互

### 实现

所有chat相关的逻辑都被封装在 ``chat`` package里，client和server的cli只负责将ui和chat粘合起来。

首先，是核心的数据结构：

```
type Message chan string

type Client struct {
    conn     net.Conn
    incoming Message
    outgoing Message
    reader   *bufio.Reader
    writer   *bufio.Writer
    quiting  chan net.Conn
    name     string
}
```

Client 是一个服务器和客户端都共享的数据结构。conn是建立的连接，reader/writer是conn上的bufio。Client与外界的接口是incoming/outgoing两个channel，即：Server 会把要发送的内容 push 到 outgoing channel 里，供writer去写；而从reader读入的数据会 push 到 incoming channel 里，供 Server 读。

每个 Client 有自己的名字，服务器端代码会使用这个名字（客户端代码不会使用）。

```
type Token chan int
type ClientTable map[net.Conn]*Client

type Server struct {
    listener net.Listener
    clients  ClientTable
    tokens   Token
    pending  chan net.Conn
    quiting  chan net.Conn
    incoming Message
    outgoing Message
}
```

Server 保存一张 ``ClientTable``。每个 accept 到的 conn 会 push 进 pending channel，等待创建client。Server有 incoming / outgoing 两个 channel，分别和 client 的 incoming / outgoing 关联。

Server 有一组 tokens，决定了一个Server最多能装多少Client（避免Server overloading）。

下面看 Server 的创建流程：

```
const (
    MAXCLIENTS = 50
)

func CreateServer() *Server {
    server := &Server{
        clients:  make(ClientTable, MAXCLIENTS),
        tokens:   make(Token, MAXCLIENTS),
        pending:  make(chan net.Conn),
        quiting:  make(chan net.Conn),
        incoming: make(Message),
        outgoing: make(Message),
    }
    server.listen()
    return server
}
```

很简单，无须多说。``server.Listen()`` 实现如下：

```
func (self *Server) listen() {
    go func() {
        for {
            select {
            case message := <-self.incoming:
                self.broadcast(message)
            case conn := <-self.pending:
                self.join(conn)
            case conn := <-self.quiting:
                self.leave(conn)
            }
        }
    }()
}
```

这是一个 goroutine，做三件事：

* 如果 ``self.incoming`` 收到东西，将其 broadcast 出去。
* 如果有新的连接，则将其接入到聊天室。
* 如果一个 Client 退出，则进行一些清理和通知。

我们先看一个新连接如何加入到聊天室：

```
func (self *Server) join(conn net.Conn) {
    client := CreateClient(conn)
    name := getUniqName()
    client.SetName(name)
    self.clients[conn] = client

    log.Printf("Auto assigned name for conn %p: %s\n", conn, name)

    go func() {
        for {
            msg := <-client.incoming
            log.Printf("Got message: %s from client %s\n", msg, client.GetName())

            if strings.HasPrefix(msg, ":") {
                if cmd, err := parseCommand(msg); err == nil {
                    if err = self.executeCommand(client, cmd); err == nil {
                        continue
                    } else {
                        log.Println(err.Error())
                    }
                } else {
                    log.Println(err.Error())
                }
            }
            // fallthrough to normal message if it is not parsable or executable
            self.incoming <- fmt.Sprintf("%s says: %s", client.GetName(), msg)
        }
    }()

    go func() {
        for {
            conn := <-client.quiting
            log.Printf("Client %s is quiting\n", client.GetName())
            self.quiting <- conn
        }
    }()
}
```

这里先通过连接建立 Client 数据，为其自动分配一个唯一的名字，然后将其加入到 ``ClientTable`` 中。注意在这个函数里每个 Client 会运行两个 goroutine，我们先记住这一点。

第一个 goroutine 从 Client 的 incoming channel 中拿出 message，如果是命令的话就执行之，否则将其放入 Server 的 incoming channel，等待被 broadcast 出去。之前 ``Listen()`` 方法里有对应的处理：

```
            case message := <-self.incoming:
                self.broadcast(message)
```

顺手看一下 ``broadcast`` 怎么做的：

```
func (self *Server) broadcast(message string) {
    log.Printf("Broadcasting message: %s\n", message)
    for _, client := range self.clients {
        client.outgoing <- message
    }
}
```

第二个 goroutine 从 Client 的 quiting channel 中拿出 conn，放入 Server 的 quiting channel 中，等待处理某个 Client 的退出。同样在 ``Listen()`` 中有处理：

```
            case conn := <-self.quiting:
                self.leave(conn)
```

顺手也看看 ``Leave`` 做些什么：

```
func (self *Server) leave(conn net.Conn) {
    if conn != nil {
        conn.Close()
        delete(self.clients, conn)
    }

    self.generateToken()
}
```

``Leave`` 里有两个坑，一个是从 map 里删除一个 key 是否需要 synchronize，我们放在下面的『并发与同步』里详细再表；另一个坑是 ``generateToken()``，马上就会讲到。

看了这么多代码了，还没看到服务器建连的代码，有点说不过去。接下来我们看 ``Start``：

```
func (self *Server) Start(connString string) {
    self.listener, _ = net.Listen("tcp", connString)

    log.Printf("Server %p starts\n", self)

    // filling the tokens
    for i := 0; i < MAXCLIENTS; i++ {
        self.generateToken()
    }

    for {
        conn, err := self.listener.Accept()

        if err != nil {
            log.Println(err)
            return
        }

        log.Printf("A new connection %v kicks\n", conn)

        self.takeToken()
        self.pending <- conn
    }
}
```

这里 ``generateToken`` 及 ``takeToken`` 与 ``Leave`` 里的 ``generateToken`` 呼应。这些代码对应一个隐式需求：服务器不可过载。所以我们有 ``MAXCLIENTS`` 来限制一个服务器的 client 上限。但是，怎么比较漂亮地处理这个上限问题？因为在一个真实的聊天场景下，聊天室里的人是可以进进出出的。

我们采用 token。系统生成有限的 token，被拿光后，当且仅当有人归还 token，等待者才能获得 token，进入聊天室。在 golang 中，goroutine 和 chan 简直是为此需求量身定制的。我们看运作机制：

* 首先生成 MAXCLIENTS 个 token。
* 第 1 - MAXCLIENTS 个 client:
    * 从 tokens 里拿走一个 token
    * 把自己的 conn 放入 pending channel（如果之前的 pending conn 还被取走，则这个 goroutine就会被挂起，等待之前的 pending conn 被取走。否则，继续执行。
* 第 (MAXCLIENTS + 1) 个 client:
    * 从 tokens 里拿不到 token 了，当前的 goroutine 在这一点上挂起，等待 token。
* 有人离开：
    * 归还一个 token，这样之前被挂起等待 token 的 goroutine 被唤醒，继续执行。 

没有使用任何同步机制，代码干净清晰漂亮，我们就完成了一个排队系统。Ura for go!

<hr/>

喘一口气，接下来看 ``join`` 的时候调用的 ``CreateClient`` 的代码：

```
func CreateClient(conn net.Conn) *Client {
    reader := bufio.NewReader(conn)
    writer := bufio.NewWriter(conn)

    client := &Client{
        conn:     conn,
        incoming: make(Message),
        outgoing: make(Message),
        quiting:  make(chan net.Conn),
        reader:   reader,
        writer:   writer,
    }
    client.Listen()
    return client
}
```

``client.Listen`` 极其细节：

```
func (self *Client) Listen() {
    go self.Read()
    go self.Write()
}

func (self *Client) Read() {
    for {
        if line, _, err := self.reader.ReadLine(); err == nil {
            self.incoming <- string(line)
        } else {
            log.Printf("Read error: %s\n", err)
            self.quit()
            return
        }
    }

}

func (self *Client) Write() {
    for data := range self.outgoing {
        if _, err := self.writer.WriteString(data + "\n"); err != nil {
            self.quit()
            return
        }

        if err := self.writer.Flush(); err != nil {
            log.Printf("Write error: %s\n", err)
            self.quit()
            return
        }
    }

}
```

``client.Listen`` 里我们也生成了两个 goroutine，加上之前的两个，每个 client 有四个 goroutine（所以运行中的Server的 gorutine 的数量接近于 client num * 4）。虽然我们可以做一些优化，但这并不要紧，一个 go 进程里运行成千上万个 goroutine没有太大问题，因为 goroutine 运行在 userspace，其 memory footprint很小（几k），切换代价非常低（没有 syscall）。

这两个 goroutine 正如一开始设计时提到的，一读一写，通过 channel 和外界交互。

这就是整个聊天室的主体代码。接下来的命令行就很简单了。

先看 Server 代码：

```
package main

import (
    . "chatroom/chat"
    "fmt"
    "os"
)

func main() {
    if len(os.Args) != 2 {
        fmt.Printf("Usage: %s <port>\n", os.Args[0])
        os.Exit(-1)
    }

    server := CreateServer()
    fmt.Printf("Running on %s\n", os.Args[1])
    server.Start(os.Args[1])

}
```

接下来是 Client 代码：

```
package main

import (
    "bufio"
    . "chatroom/chat"
    "fmt"
    "log"
    "net"
    "os"
)

func main() {
    if len(os.Args) != 2 {
        fmt.Printf("Usage: %s <port>\n", os.Args[0])
        os.Exit(-1)
    }

    conn, err := net.Dial("tcp", os.Args[1])

    if err != nil {
        log.Fatal(err)
    }

    defer conn.Close()
    in := bufio.NewReader(os.Stdin)
    out := bufio.NewWriter(os.Stdout)

    client := CreateClient(conn)

    go func() {
        for {
            out.WriteString(client.GetIncoming() + "\n")
            out.Flush()
        }
    }()

    for {
        line, _, _ := in.ReadLine()
        client.PutOutgoing(string(line))
    }

}
```

运行一下（起了两个client）：

```
➜  chatroom git:(master) ./bin/chatserver :5555
➜  chatroom git:(master) ./bin/chatserver :5555
Running on :5555
2014/01/30 09:05:24 Server 0xc2000723c0 starts
2014/01/30 09:05:34 A new connection &{{0xc20008f090}} kicks
2014/01/30 09:05:34 Auto assigned name for conn 0xc200000100: User 0
2014/01/30 09:05:48 A new connection &{{0xc20008f120}} kicks
2014/01/30 09:05:48 Auto assigned name for conn 0xc200000148: User 1
2014/01/30 09:06:39 Got message: Hello from client User 0
2014/01/30 09:06:39 Broadcasting message: User 0 says: Hello
2014/01/30 09:06:48 Got message: :name Tyr from client User 1
2014/01/30 09:06:48 Broadcasting message: Notification: User 1 changed its name to Tyr
2014/01/30 09:06:57 Got message: Hello world! from client User 0
2014/01/30 09:06:57 Broadcasting message: User 0 says: Hello world!
2014/01/30 09:07:01 Got message: Hello from client Tyr
2014/01/30 09:07:01 Broadcasting message: Tyr says: Hello
2014/01/30 09:08:19 Read error: EOF
2014/01/30 09:08:19 Client User 0 is quiting
2014/01/30 09:08:19 Broadcasting message: Notification: User 0 quit the chat room.
```

其中一个 client：
```
➜  chatroom git:(master) ./bin/chatclient :5555
User 0 says: Hello
:name Tyr
Notification: User 1 changed its name to Tyr
User 0 says: Hello world!
Hello
Tyr says: Hello
Notification: User 0 quit the chat room.
```

完整代码请见 [github repo](https://github.com/tyrchen/chatroom)。

以上代码能正确运行，不过还有不少问题，比如 server stop 时 goroutine 并未正确 cleanup。但对于理解 ``goroutine`` 和 ``chan`` 来说，不失为一个很好的例子。

## Lessons learnt

### 使用go test

我现在写代码已经离不开非常方便的 ``go test`` 了。golang 的开发者们非常聪明，他们知道把一个 test framework / utility 放在核心的安装包中是多么重要。这个 chatroom 是迭代开发的，你可以 checkout v0.1/v0.2/v0.3 分别看不同时期的代码。每次添加新功能，或者重构代码时，``go test ./chat`` 就是我信心的保证。代码和test case同步开发，新的 feature 有新的 case 去 cover，这样一点点做上去。拿柳总的话说，就是：『垒一层土，夯实，再垒一层』。

例子：

```
➜  chatroom git:(master) go test ./chat
ok      chatroom/chat   0.246s
```

### 并发与同步

golang 在设计时做了很多取舍。其中，对map的操作是否原子就有很多 debate。最终，为了 performance，map 的操作不具备原子性，亦即不是 multithread safe。所以，正确的做法是在从 map 中删除一个 conn 时和使用 ``range`` 中读取时做读写同步。由于本例运行在单线程环境下（是的，如果你不指定，golang process 默认单线程），且以教学为目的，实在不忍用难看的同步操作降低代码的美感。

另外一种做法是在读写两个需要同步的地方使用 channel 进行同步（还记得刚刚讲的 token）吧？

如果你对 map 的 thread-safe 感兴趣，可以读读 [stackoverflow上的这个问题](http://stackoverflow.com/questions/12938233/is-getting-a-value-using-range-not-thread-safe-in-go)。

### 通过close来向所有goroutine传递终止讯息

在我的代码里，close 做得比较 ugly，不知你是否感受到了。更好的做法是使用 ``close`` 一个 channel 来完成关闭 goroutine 的动作。当 close 发生时，所有接收这个 channel 的 goroutine 都会收到通知。下面是个简单的例子：

```
package main

import (
    "fmt"
    "strconv"
    "time"
)

const (
    N = 10
)

func main() {
    quit := make(chan bool)

    for i := 0; i < N; i++ {
        go func(name string) {
            for {
                select {
                case <-quit:
                    fmt.Printf("clean up %s\n", name)
                    return
                }
            }
        }(strconv.Itoa(i))
    }
    close(quit)

    for {
        time.Sleep(1 * time.Second)
    }
}
```

我生成了 N 个 goroutine，但只需使用一个 ``close`` 就可以将其全部关闭。在 chatroom 代码中，关闭 server 时，也可以采用相同的方法，关闭所有的 client 上的 goroutine。

下面是上述代码执行的结果：

```
➜  terminate  go run terminate.go
clean up 0
clean up 1
clean up 2
clean up 3
clean up 4
clean up 5
clean up 6
clean up 7
clean up 8
clean up 9
```

### 尽可能把任务分布在goroutine中

如果你没有看过 Rob Pike 的 [Concurrency is not parallelism](http://blog.golang.org/concurrency-is-not-parallelism)，建议一定要看，不管你有没有 golang 的 background。Concurrency 是你写软件的一种追求，和是否并行无关，但和模块化，简单，优雅有关。

### goroutine不可做无阻塞的infinite loop

goroutine，至少在 golang 1.2 及之前的版本，都运行在一个 cooperative multitasking 的 scheduler 上。所以你要保证你的任何一个 infinite loop 都要有可能被 block 住，无论是 block 在 IO, chan, 还是主动 block 在 timer 上，总之，infinite loop 要有退出机制。刚才的例子我们稍微改改：

```
package main

import (
    "fmt"
    "strconv"
    //"time"
)

const (
    N = 10
)

func main() {
    quit := make(chan bool)

    for i := 0; i < N; i++ {
        go func(name string) {
            for {
                select {
                case <-quit:
                    fmt.Printf("clean up %s\n", name)
                    return
                }
            }
        }(strconv.Itoa(i))
    }
    close(quit)

    for {
        //time.Sleep(1 * time.Second)
    }
}
```

乍一看，这个例子中的 gorountine应该能收到 ``close`` 而自我关闭。在 ``main`` 执行的过程中，头十个新创建出来的 ``goroutine`` 还未得到调度。虽然在 main 里我们 close 了 quit，但由于接下来的 dead loop 一直不释放 CPU，所以其他 goroutine 一直得不到调度。运行的话没有任何输出：

```
➜  terminate  go run terminate.go
^Cexit status 2
```

我们稍稍改改这个程序：

```
package main

import (
    "fmt"
    "runtime"
    "strconv"
    //"time"
)

const (
    N = 10
)

func main() {
    runtime.GOMAXPROCS(2)
    quit := make(chan bool)

    for i := 0; i < N; i++ {
        go func(name string) {
            for {
                select {
                case <-quit:
                    fmt.Printf("clean up %s\n", name)
                    return
                }
            }
        }(strconv.Itoa(i))
    }
    close(quit)

    for {
        //time.Sleep(1 * time.Second)
    }
}
```

现在允许这个程序运行在两个 thread 上。这样就能正常运行了。但切记，没有阻塞机制的 infinite loop 不是一个好的设计。

```
➜  terminate  go run terminate1.go
clean up 0
clean up 1
clean up 2
clean up 3
clean up 4
clean up 5
clean up 6
clean up 7
clean up 8
clean up 9
^Cexit status 2
```

### DRY (Don't Repeat Yourself)

写 chatroom 时，我不断重构代码，其目的就是能让代码干净，漂亮。比方我的一次 commit：``git diff 39690d9 6851177``，就是在做 test case refactor。

DRY 的前提是有完善的 test case，前文也提到。这是项目内部的 DRY。

另外一种 DRY 的方式是（从我途客圈的前同事 @chenchiyuan 那里学到的）：如果两个或以上的项目中都用到类似结构的代码，则考虑将其重构到一个第三方的 lib 里。在 chatroom 中，有两处这样的重构，重构在我的 [goutil](https://github.com/tyrchen/goutil) 项目中。

第一处是生成唯一数：

```
package uniq

var (
        num = make(chan int)
)

func init() {
        go func() {
                for i := 0; ; i++ {
                        num <- i
                }
        }()
}

func GetUniq() int {
        return <-num
}
```

第二处是正则表达式匹配，将匹配的结果放入一个 map 的 slice 里：

```
package regex

import (
        "regexp"
)

const (
        KVPAIR_CAP = 16
)

type KVPair map[string]string

func MatchAll(r *regexp.Regexp, data string) (captures []KVPair, ok bool) {
        captures = make([]KVPair, 0, KVPAIR_CAP)
        names := r.SubexpNames()
        length := len(names)
        matches := r.FindAllStringSubmatch(data, -1)
        for _, match := range matches {
                cmap := make(KVPair, length)
                for pos, val := range match {
                        name := names[pos]
                        if name != "" {
                                cmap[name] = val
                        }
                }
                captures = append(captures, cmap)
        }
        if len(captures) > 0 {
                ok = true
        }
        return
}
```

总结一条铁律：project 级的 DRY 是函数化，package化；cross project的 DRY 是 repo 化。

## 后记

大过年的，我这么嘚吧嘚吧地你也读得挺累，感谢你一路读到这里，新年快乐！

![小宝](/assets/files/photos/baby20140130.jpg)