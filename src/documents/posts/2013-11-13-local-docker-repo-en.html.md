---
layout: post
title: Build Your Own Docker Registry with DigitalOcean
date: 2013-11-13 22:40
comments: true
tags: [tool, technology, docker]
cover: /assets/files/posts/container.jpg
---

# Build Your Own Docker Registry with DigitalOcean

[Docker](http://www.slideshare.net/dotCloud/why-docker) might be the most attracting open source technologies in 2013. By providing a higher level API and management UI, it make linux container much more usable. If you haven't tried it, [try it](http://www.docker.io/gettingstarted/). You will then feel it is "[the git for deployment](http://blog.scoutapp.com/articles/2013/08/28/docker-git-for-deployment)".

After you played with it for a while, enjoying the git like operation for your software and their dependencies, a natural question will appear: how can I build my own private docker registry that I could leverage for my own IT infrastructure? 

The docker-registry comes to help you. docker-registry is a software to provide similar functionality as [official docker index](http://index.docker.io/), which is a central registry for you to commit your new images, pull existing ones, etc. It can let you to build your own docker registry that is private, secure and speedy.

## Install docker-registry

First of all, let's clone docker-registry：

~~~
git clone https://github.com/dotcloud/docker-registry
cd docker-registry
cp config_sample.yml config.yml
~~~

You need then to open config.yml to set the dev (the default profile) storage to something like `/var/docker/registry`:

~~~
# This is the default configuration when no flavor is specified
dev:
    storage: local
    storage_path: /var/docker/registry
    loglevel: debug
~~~

Then create this directory and grant 

~~~
sudo mkdir -p /var/docker/registry
sudo chown -R `whoami` /var/docker
~~~

As docker-registry uses python and ssl, you need to install the following libraries:

~~~
sudo apt-get install build-essential python-dev libevent-dev python-pip libssl-dev
~~~

Then you can setup your virtualenv and install requirements:

(optional) install virtualenv if you haven't:
~~~
sudo pip install virtualenv
~~~

setup virtualenv:

~~~
virtualenv --no-site-packages venv
. venv/bin/activate
pip install -r requirements.txt
~~~

Now your docker-registry should be run via:

~~~
gunicorn -k gevent --max-requests 100 --graceful-timeout 3600 -t 3600 -b localhost:8080 -w 8 wsgi:application
~~~

You can open your browser on `http://localhost:8080` to see if it works. It should show you:

~~~
"docker-registry server (dev)"
~~~

Congratulations! The minimum installation is done. However, if you want to run it like a normal service, you need to configure supervisor and nginx. Let's continue our journey.

## Run docker-registry as a service

If you don't have supervisor installed, please install it firstly:

~~~
sudo apt-get install supervisor
~~~

Then add a new configuration file:

~~~
sudo vim /etc/supervisor/conf.d/docker-registry.conf
~~~

In the opened vim editor, copy and paste the following content, save and quit (you need to change dev to your local user):

~~~
[program:docker-registry]
directory=/home/dev/deployment/docker-registry
user=dev
command=/home/dev/deployment/docker-registry/venv/bin/gunicorn -b 0.0.0.0:7030 -k gevent --max-requests 100 --graceful-timeout 3600 -t 3600 -w 8 wsgi:application
redirect_stderr=true
stderr_logfile=none
stdout_logfile=/var/log/supervisor/docker-registry.log
autostart=true
autorestart=true
~~~

Then reload supervisor to make it take effects.

~~~
$ sudo supervisorctl
supervisor> reread
docker-registry: available
supervisor> update
docker-registry: added process group
supervisor> status
docker-registry                  RUNNING    pid 4371, uptime 0:00:01
~~~

If you see RUNNING int the status output, then it means your docker-registry is up and running normally. If not, please got to `/var/log/supervisor/docker-registry.log` to see what happened.

Next you need to use nginx to proxy the requests to docker-registry. If you don't have nginx installed, please install it firstly:

~~~
sudo apt-get install nginx
~~~

Then add a new configuration file:

~~~
sudo vim /etc/nginx/sites-available/docker-registry
~~~

Copy and paste the following content, then save and quite:

~~~
server {
  listen 80;
  client_max_body_size 200m;
  server_name your-domain.com;
  access_log /var/log/nginx/docker-registry.access.log;
  error_log /var/log/nginx/docker-registry.error.log;
  location / {
    proxy_pass http://localhost:8080;
    include /etc/nginx/proxy_params;
  }
}
~~~

Note that you need `client_max_body_size 200m` to allow big file post. If later your found error like:

~~~
2013/11/12 03:35:18 Received HTTP code 413 while uploading layer
~~~

You need to enlarge this value.

Then you need to soft link this file to `sites-enabled` and restart nginx:

~~~
cd /etc/nginx/sites-enabled/
sudo ln -s ../sites-available/docker-registry docker-registry
sudo service nginx restart
~~~

Open your browser to visit `http://your-domain.com`, you should see the same result as previous step:

~~~
"docker-registry server (dev)"
~~~

## Use your private docker registry

First of all, let's see what images we have so far:

~~~
$ sudo docker images
REPOSITORY                            TAG                   IMAGE ID            CREATED             SIZE
ubuntu                                12.04                 8dbd9e392a96        7 months ago        131.5 MB (virtual 131.5 MB)
ubuntu                                latest                8dbd9e392a96        7 months ago        131.5 MB (virtual 131.5 MB)
ubuntu                                precise               8dbd9e392a96        7 months ago        131.5 MB (virtual 131.5 MB)
ubuntu                                12.10                 b750fe79269d        7 months ago        24.65 kB (virtual 180.1 MB)
base                                  latest                b750fe79269d        7 months ago        24.65 kB (virtual 180.1 MB)
ubuntu                                quantal               b750fe79269d        7 months ago        24.65 kB (virtual 180.1 MB)
base                                  ubuntu-12.10          b750fe79269d        7 months ago        24.65 kB (virtual 180.1 MB)
base                                  ubuntu-quantal        b750fe79269d        7 months ago        24.65 kB (virtual 180.1 MB)
base                                  ubuntu-quantl         b750fe79269d        7 months ago        24.65 kB (virtual 180.1 MB)
~~~

If you don't have any docker images, please use `sudo docker pull base` to pull base images from docker repository.

We would like to push the base image to our own shiny registry. First of all, tag it to push to your own server:

~~~
sudo docker tag b750fe79269d your-domain.com/yourname/base
~~~

Then push:

~~~
sudo docker push your-domain.com/yourname/base
~~~

If push succeeded, you will see your images with `docker images`:

~~~
$ sudo docker images
REPOSITORY                            TAG                   IMAGE ID            CREATED             SIZE
ubuntu                                12.04                 8dbd9e392a96        7 months ago        131.5 MB (virtual 131.5 MB)
ubuntu                                latest                8dbd9e392a96        7 months ago        131.5 MB (virtual 131.5 MB)
ubuntu                                precise               8dbd9e392a96        7 months ago        131.5 MB (virtual 131.5 MB)
ubuntu                                12.10                 b750fe79269d        7 months ago        24.65 kB (virtual 180.1 MB)
base                                  latest                b750fe79269d        7 months ago        24.65 kB (virtual 180.1 MB)
your-domain.com/yourname/base        latest                b750fe79269d        7 months ago        24.65 kB (virtual 180.1 MB)
ubuntu                                quantal               b750fe79269d        7 months ago        24.65 kB (virtual 180.1 MB)
base                                  ubuntu-12.10          b750fe79269d        7 months ago        24.65 kB (virtual 180.1 MB)
base                                  ubuntu-quantal        b750fe79269d        7 months ago        24.65 kB (virtual 180.1 MB)
base                                  ubuntu-quantl         b750fe79269d        7 months ago        24.65 kB (virtual 180.1 MB)
~~~

It is already available locally, so you can try it：

~~~
sudo docker run -i -t your-domain.com/yourname/base /bin/bash
~~~

If you want to pull this image from other machine, just use:

~~~
sudo docker pull your-domain.com/yourname/base
~~~

Have fun!


