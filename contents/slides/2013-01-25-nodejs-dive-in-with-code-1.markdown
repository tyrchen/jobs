---
template: slide.jade
theme: beige
title: nodejs dive in with code (1)
date: 2013-01-25 06:46
comments: true
tags: [node]
---

    # Nodejs Dive In With Code (1)
    ### Tyr Chen
    ### 2013-01-25 @ subway line 10



<!--more-->



    ## First Server



    ## Hello World
    
    ```
    var http = require('http');

    var s = http.createServer(function(req, res) {
      res.writeHead(200, { 'content-type': 'text/plain' });
      res.write('hello\n\n');
      res.end('crucial world!\n');
    }).listen(8000);
    ```



    ## Test and Introspection
    
    ```
    $ curl -i http://localhost:8000/
    HTTP/1.1 200 OK
    content-type: text/plain
    Date: Thu, 24 Jan 2013 22:53:10 GMT
    Connection: keep-alive
    Transfer-Encoding: chunked

    hello

    crucial world!
    ```



    ## Response Header

    * keep-alive
    * chunked



    ## Hello World (2)
    ```
    var http = require('http');

    var s = http.createServer(function(req, res) {
      res.writeHead(200, { 'content-type': 'text/plain' });
      res.write('hello\n\n');
      setTimeout(function() {
        res.end('crucial world!\n');
      }, 2000);
    }).listen(8000);
    ```



    ## What Happened?

    * via curl
    * via browser



    __I like HTTP, how about a TCP server?__



    ## TCP Server
    ```
    var net = require('net');

    var server = net.createServer(function(socket) {
      socket.write('hello\n');
      socket.write('crucial world\n');

    }).listen(8000);
    ```



    __I would like to make it more interactive...__



    ## Echo Server
    ```
    var net = require('net');

    var server = net.createServer(function(socket) {
      socket.write('hello\n');
      socket.write('world\n');

      // wait for data arrival event
      socket.on('data', function(data) {
        socket.write(data);
      });
    }).listen(8000);
    ```



    __What about UDP and Raw Socket?__



    ## Well this is a good question
    * Node support UDP in dgram module
    * Node doesn't support raw socket (you can't do Ping directly)
    
    *Maybe joyent thought it is a poor choice for you to choose javascript to do raw socket...*


    # A simple UDP Server

    ```
    var dgram = require('dgram');
    var message = new Buffer("Hello world");
    var client = dgram.createSocket("udp4");
    client.send(message, 0, message.length, 12345, "localhost", function(err, bytes) {
      client.close();
    });
    ```




    __Let's writing something a bit complicated__



    ## A Chat Server
    ```
    var net = require('net');
    var sockets = [];
    var s = net.Server(function(socket) {
      sockets.push(socket);

      socket.on('data', function(data) {
        for(var i=0; i<sockets.length; i++) {
          if (sockets[i] == socket) continue;
          sockets[i].write(data);
        }
      });

      socket.on('end', function() {
        var i = sockets.indexOf(socket);
        sockets.splice(i, 1);
      });
    }).listen(8000);
    ```



    # To Be Continued...