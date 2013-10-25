---
template: slide.jade
title: Nodejs basics
date: 2013-01-20 22:58
theme: default
transition: cube
tags: [node]
---

    # Nodejs Basics
    ### Tyr Chen
    2013-01-20


<!--more-->


    ## What is Node?
    * server side javascript
    * Driven by V8 engine
    * Non blocking
    * Event driven
    * Single thread



    ## Non blocking?

    ```
    data = open('very-big-file.younameit').read()
    complexOperation(data)
    ```

    #### I/O blocking, poor performance
    #### Python, ruby, java is I/O blocking by default

    

    ## Why I/O blocking bad?



    ![IO wait](/assets/img/snapshots/iowait.jpg)



    ## The Node Way

    ```
    fs.read('very-big-file.younameit', function(data) {
    complexOperation(data);
    });

    // you can do a lot when waiting for data
    doOtherStuff();
    ```

    #### Do a lot more while waiting for I/O



    ## Event Driven?

    ```
    deploy()
    while not deployed:
      os.sleep(1000)

    # deployed, now we can do auto test
    run_test()
    ```

    ### ugly



    ## The Node Way

    ```
    deploy(function() {
    run_test();
    });
    ```

    ### elegant code, different way of thinking



    ## How does this work?



    ![Nodejs event loop](/assets/img/snapshots/eventloop.jpg)



    ## Single Thread
    ### Node runs on single thread

    ```
    fs.read('very-big-file.younameit', function(data) {
    complexOperation(data); // never fired
    });

    // you can do a lot when waiting for data
    while(true) {
    doOtherStuff(); // hogging the CPU
    }
    ```


    ## The Node Way
    * Frontend node farm
    * for providing great user experience
    * e.g. dealing with image uploading
    * Backend node workers
    * for dealing with heavy processing
    * e.g. dealing with image encoding



    ## Node Package Manager (NPM)

    * Ship with nodejs since v0.6.x
    * Help with the package management
    * gem for ruby, pip for python
    * Resolve the dependencies for you
    * package.json



    ## An example of package.json
    ```
    {
      "name": "barr",
      "description": "",
      "version": "0.1.0",
      "dependencies": {
        "wrench": "latest"
      },
      "engines": {
        "node": "0.8.16",
        "npm": "1.1.x"
      },
      "devDependencies" : {
        "coffee-script": "latest",
        "simple-http-server": "latest",
        "jade": "latest",
        "jake": "latest"
      }
    }
    ```


    ## Not The End - To Be Con...