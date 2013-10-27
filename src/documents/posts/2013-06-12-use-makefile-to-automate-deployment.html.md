---
layout: post
theme: default
title: 使用Makefile自动化部署
date: 2013-06-12 07:14
comments: true
tags: [automation, technology]
cover: /assets/files/posts/automation.jpg
---

有时候，写个小app，部署是件麻烦的事情 —— 你需要登录到服务器上，手工编辑nginx，supervisor等配置文件，然后重启相关的服务。这些配置都不在版本库中，所以也无法记录历史修订。``puppet`` 是个不错的解决方案，但对于小项目来说，使用puppet是个负担。

本文讨论如何通过写个简单的 ``makefile`` 来达到自动化部署的目的。

<!--more-->

## 本地化服务器配置

首先要做的是將服务器的配置本地化，放在自己的项目中：

![项目目录结构](/assets/files/snapshots/project_layout.jpg)

图中，_deploy目录下的内容就是我们要部署到服务器上的配置，其目录结构和服务器要完全一致，这样可以用 ``cp`` 直接將文件拷贝过去：

    ```
    $ sudo cp -r _deploy/etc/. /etc/.
    ```

这里有个问题，sudo一般需要输密码，但这里如果停下来等待用户交互，就无法完全自动化了。所以我们需要让 ``cp`` 无须password就可以执行。但又引来一个问题：无密码限制的 ``cp`` 太危险，可能会导致误操作。所以我们就把 ``cp`` copy 一份出来，叫 ``sucopy``，然后对其设置 nopassword:

    ```
    $ sudo cp /bin/cp /bin/sucopy
    $ sudo visudo
    ```

在打开的编辑窗口，为当前用户设置 ``sudo`` 选项：

    ```
    dev ALL=(ALL) NOPASSWD: /usr/bin/supervisorctl, /etc/init.d/nginx, /bin/sucopy, /usr/bin/apt-get
    ```

我这里把 ``apt-get``，``supervisorctl`` 和 ``nginx`` 都设置为 ``NOPASSWD``，也是为了自动运行。

注：如果 ``visudo`` 使用的nano编辑器不是你的菜，可以用 ``update-alternatives --config editor`` 切换成vim。

设置完成后，我们就可以在makefile中用 ``sucopy`` 把项目中的配置文件直接更新系统中的对应文件了，比如：

    ```
    sudo sucopy -r _deploy/etc/. /etc/.
    ```

很简单吧。这样做的好处是配置文件的修改随着项目文件一起在版本库中控制，部署起来也方便很多。

nginx和supervisor的配置很简单，这里就给个例子，不解释：

nginx配置：

    ```
    tchen@tchen-mbp: ~/projects/kahn/_deploy/etc/nginx/sites-available on master$ cat kahn
    server {
      listen 80;
      server_name api.awesome-server.com;
      access_log /var/log/nginx/kahn.access.log;
      error_log /var/log/nginx/kahn.error.log;
      location / {
        proxy_pass http://localhost:6080;
        include /etc/nginx/proxy_params;
      }
    }
    ```

    ```
    tchen@tchen-mbp: ~/projects/kahn/_deploy/etc/nginx/sites-enabled on master$ ls -l
    total 8
    lrwxr-xr-x  1 tchen  522017917  23 Jun 11 13:48 kahn -> ../sites-available/kahn
    ```

supervisor配置：

    ```
    tchen@tchen-mbp: ~/projects/kahn/_deploy/etc/supervisor/conf.d on master$ cat kahn.conf
    [program:kahn]
    directory=/home/dev/deployment/kahn
    user=dev
    command=coffee app.coffee
    redirect_stderr=true
    stderr_logfile=none
    stdout_logfile=/var/log/supervisor/kahn.log
    autostart=true
    autorestart=true
    ```

## Makefile

解决了服务器的本地化配置问题，自动化部署就不在话下。这里只自动化了下列任务，对简单的小项目来说足够了：

* 代码更新。
* 依赖更新。（python的用户可以把 ``npm install`` 换成 ``pip install -r requirements.txt``）
* 配置更新。
* supervisor设置更新及重启。
* nginx重启。

Makefile文件比较简单，不解释了。注意这里我们把 ``remote_deploy`` 放在第一位，让 ``make`` 缺省调用时可以调用它，这样，我们会自动登录到服务器上（服务器的连接请使用rsa key，避免输入密码），pull代码，然后执行 ``make deploy`` 进行部署。

    ```
    tchen@tchen-mbp: ~/projects/kahn on master$ cat Makefile
    CHECK=\033[32m✔\033[39m
    DONE="\n$(CHECK) Done.\n"

    SERVER=awesome-server.com
    PROJECT=kahn
    PATH=deployment/$(PROJECT)
    SUPERVISORCTL=/usr/bin/supervisorctl
    SUCOPY=/bin/sucopy
    SSH=/usr/bin/ssh
    ECHO=/bin/echo -e
    NPM=/usr/local/bin/npm
    SUDO=/usr/bin/sudo

    remote_deploy:
        @$(SSH) -t $(SERVER) "echo Deploy $(PROJECT) to the $(SERVER) server.; cd $(PATH); git pull; make deploy;"

    dependency:
        @$(ECHO) "\nInstall project dependencies..."
        @$(NPM) install

    configuration:
        @$(ECHO) "\nUpdate configuration..."
        @$(SUDO) $(SUCOPY) -r _deploy/etc/. /etc/.

    supervisor:
        @$(ECHO) "\nUpdate supervisor configuration..."
        @$(SUDO) $(SUPERVISORCTL) reread
        @$(SUDO) $(SUPERVISORCTL) update
        @$(ECHO) "\nRestart $(PROJECT)..."
        @$(SUDO) $(SUPERVISORCTL) restart $(PROJECT)

    nginx:
        @$(ECHO) "\nRestart nginx..."
        @$(SUDO) /etc/init.d/nginx restart

    deploy: dependency configuration supervisor nginx
        @$(ECHO) $(DONE)
    ```

大功告成。试试吧：

    ```
    tchen@tchen-mbp: ~/projects/kahn on master$ make
    Deploy kahn to the awesome-server.com server.
    Current branch master is up to date.

    Install project dependencies...

    Update configuration...

    Update supervisor configuration...
    No config updates to processes

    Restart kahn...
    kahn: stopped
    kahn: started

    Restart nginx...
    Restarting nginx: nginx.

    ✔ Done.

    Shared connection to awesome-server.com closed.
    ```

送上小宝的近照一张：

![小宝近期照片](/assets/files/photos/baby20130612.jpg)