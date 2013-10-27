---
layout: post
theme: default
title: why every developer should use mac
date: 2013-05-09 08:34
comments: true
tags: [mac, thought]
cover: /assets/files/posts/apple_mac.jpg
---

Two years ago, I bought my own 13" mbp. From then on, I never left mac world, only changed that little thing to a new 15" retina mbp. From my two years experience, I believe to make your development work much more productive, you shall use mac.

<!--more-->

## Shell

The No.1 reason regards with the powerful shell. This is something windows could never compete with *nix world. Shell releases your from the burden of GUI, let you think and do like a guru. GUI means endless mouse clicks, interweaving with keyboard presses - it's unproductive, and un-automatable; in contrast, shell means almost only keyboard presses, you can automate as much as possible.

How many times you login into eng-shell to do your work? In osx, you can use "ssh-copy-id" to copy your public key to your engineering server so that you don't need to enter your password again and again. If you feel "ssh eng-shell5.your-domain.net" is too long to enter, you can alias it to something like "eng5". Don't neglect these tiny improvements, lots of precious time slipped in this way. Let's do a comparison between windows users (secureCRT) and osx users (shell). Windows user need to move their hand from keyboard to mouse, then click the menu in SecureCRT, find and select a stored eng-shell5 session from a number of sessions, click, then move the hand from mouse to keyboard, then enter password and start to work. Mac user only need to cmd+t (if you're using iTerm) to open a new terminal tab, press "eng5", then start to work.

There are much more approaches to be productive. If you want to download a file from bug tracking system (BTS) to analyze, that means a series of clicks and switching between windows. But in mac, you can just copy the link and use "wget" or "curl" to store it. You can then "open" the file in the same terminal. How about your BTS use HTTP authentication? No worry, you just need to make an alias with wget like "alias wget-gnats="wget --http-user=tchen --http-password=". Next time you just need "wget-bts".

You can also write more complicated scripts to make you as productive as possible. Standard osx ships with at least python, ruby. You can install your own favorite programming languages quite easily.

Now you may understand the philosophy in the *nix world - Do something in a inelegant way in the first time, do the same thing elegant afterwards. Unfortunately, you need to do things clumsily again and again in windows.

## Software

Second reason is the software. What software you use defines what kind of engineer you're. vim/emacs/sublime/etc. compared with NotePad, chrome/safari/firefox compared with Internet Explorer, iTerm/Terminal compared with SecureCRT, space (virtual desktop) compared with ??, sips compared with Paint (lots of times I just want to resize images), python/ruby/gcc/wget/ssh/git/etc. compared with ?? (maybe cygwin?). To a developer, the softwares in mac or *nix world surpass those in windows at least a mile. Try it, you'll know.

You may say most of these softwares could be found in windows as well. The question is, if you use them in your windows, why not switch to osx for the native or better experience?

Space, aka virtual desktop, is another great accelerator. You can flip with 4 fingers on the touch pad to switch between spaces. You can assign outlook, lync, safari to one space and iTerm, chrome, sublime to another space. That will separate your development task from your communication task so that the communication softwares cannot disturb you when you're in a flow of development or problem solving.

## Aesthetic Perception

Third reason is related with aesthetic perception. ThinkPad/Windows never let you feel beautiful. But every part of macbook pro/osx tells you what is the beauty and perfection. Macbook pro itself is an art. So the quality of software in it inherit this characteristic.

Engineers should pursue beauty and perfection. Only that their software could be beautiful and perfect.



