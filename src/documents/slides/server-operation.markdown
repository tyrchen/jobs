---
layout: slide
title: "server operation"
date: 2013-01-11 07:18
theme: sky
---

    # Supervisor and Nginx
    ### Tyr Chen

    2013-01-11


<!--more-->


    ## Supervisor Conf

    /et/supervisor/supervisor.conf

    ```
    [program:babble]
    directory=/home/tchen/deployment/babble
    user=tchen
    command=node main.js
    environment=PORT=7003,ROOT_URL="http://tchen.me",MONGO_URL="mongodb://localhost:27017/babble"
    redirect_stderr=true
    stderr_logfile=none
    stdout_logfile=/var/log/supervisor/babble.log
    autostart=true
    autorestart=true
    ```


    ## Supervisor command
    ```
    $ supervisorctl
    babble                           RUNNING    pid 11486, uptime 39 days, 10:42:25
    blog:celeryd                     RUNNING    pid 17088, uptime 47 days, 8:59:25
    blog:server                      FATAL      Exited too quickly (process log may have details)
    dmall                            STOPPED    Dec 27 10:17 AM
    projects                         RUNNING    pid 24040, uptime 36 days, 0:05:09
    teamspark                        STOPPED    Dec 04 08:34 AM
    $ rearead
    $ update
    $ restart babble
    ```

