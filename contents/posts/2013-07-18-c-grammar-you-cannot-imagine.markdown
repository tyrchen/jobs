---
template: post.jade
theme: default
title: 你无法想象的C语法
date: 2013-07-18 08:22
comments: true
tags: [c, language]
---

## 引子

看了berkeley网站上的文章[Who Says C is Simple?](http://www.cs.berkeley.edu/~necula/cil/cil016.html)，顿感汗流浃背。如果招聘官按照这个题目去面试，我也就将将五十分。不过话说回来，这里所列的case都太偏门，走的是圣火令的武功路数，真正做工程的这么写代码就是欠揍。

但是抱着学语言的态度，这里的题目如果你不懂都值得深究。我研究了下第四题 —— 这是让我比较困惑的一题。

```
// Functions and function pointers are implicitly converted to each other.
int (*pf)(void);
int f(void) {

   pf = &f; // This looks ok
   pf = ***f; // Dereference a function?
   pf(); // Invoke a function pointer?     
   (****pf)();  // Looks strange but Ok
   (***************f)(); // Also Ok             
}
```

<!--more-->

## 探讨

这个代码直接运行的话肯定是Segment Fault。从第3句起就是个无限递归。作者想揭示的问题并不在此，所以我的测试代码做了小小修改：

```
#include <stdio.h>

int (*pf)(void);

int f(void) {
    printf("Hello world!\n");
}

int main() {
    f();
    (&f)();
    (*f)();
    (************f)();
    pf = &f;
    pf();
    pf = *f;
    pf();
}
```

运行起来和预期一致：

```
vagrant@vagrant-ubuntu-raring-64:~/arena$ ./fp
Hello world!
Hello world!
Hello world!
Hello world!
Hello world!
Hello world!
```

我们来看看汇编出来的结果（arm）：

```
00008440 <f>:
    8440:   e92d4800    push    {fp, lr}
    8444:   e28db004    add fp, sp, #4
    8448:   e59f0008    ldr r0, [pc, #8]    ; 8458 <f+0x18>
    844c:   ebffffa2    bl  82dc <_init+0x20>
    8450:   e1a00003    mov r0, r3
    8454:   e8bd8800    pop {fp, pc}
    8458:   00008528    .word   0x00008528

0000845c <main>:
    845c:   e92d4800    push    {fp, lr}
    8460:   e28db004    add fp, sp, #4
    8464:   ebfffff5    bl  8440 <f>
    8468:   ebfffff4    bl  8440 <f>
    846c:   ebfffff3    bl  8440 <f>
    8470:   ebfffff2    bl  8440 <f>
    8474:   e59f3030    ldr r3, [pc, #48]   ; 84ac <main+0x50>
    8478:   e59f2030    ldr r2, [pc, #48]   ; 84b0 <main+0x54>
    847c:   e5832000    str r2, [r3]
    8480:   e59f3024    ldr r3, [pc, #36]   ; 84ac <main+0x50>
    8484:   e5933000    ldr r3, [r3]
    8488:   e12fff33    blx r3
    848c:   e59f3018    ldr r3, [pc, #24]   ; 84ac <main+0x50>
    8490:   e59f2018    ldr r2, [pc, #24]   ; 84b0 <main+0x54>
    8494:   e5832000    str r2, [r3]
    8498:   e59f300c    ldr r3, [pc, #12]   ; 84ac <main+0x50>
    849c:   e5933000    ldr r3, [r3]
    84a0:   e12fff33    blx r3
    84a4:   e1a00003    mov r0, r3
    84a8:   e8bd8800    pop {fp, pc}
    84ac:   0001102c    .word   0x0001102c
    84b0:   00008440    .word   0x00008440
```

我们可以看到 ``f()``，``(&f)()``，``(*f)()``，``(************f)()`` 编译出来的结果均为 ``bl 8440 <f>``。而无论对 ``pf`` 赋值为 ``&f``，还是 ``*f``，其代码都是：

```
    8474:   e59f3030    ldr r3, [pc, #48]   ; 84ac <main+0x50>
    8478:   e59f2030    ldr r2, [pc, #48]   ; 84b0 <main+0x54>
    847c:   e5832000    str r2, [r3]
    8480:   e59f3024    ldr r3, [pc, #36]   ; 84ac <main+0x50>
    8484:   e5933000    ldr r3, [r3]
    8488:   e12fff33    blx r3
```

这个代码很好理解，就是把 ``f()`` 的地址取出来，存入 ``pf``，然后执行 ``pf()``（注意arm会把全局地址存放在使用它的函数的末尾，这样可以一条指令取出地址）。问题是，为何 ``&f`` 和 ``*f`` 在这里是等价的？

## *和&

我们知道，``*`` 是解引用，``&`` 是引用，下面的代码，前者取值，后者取地址：

```
#include <stdio.h>

int print(int x)
{
    printf("value is %x\n", x);
}

int main()
{
    int a;
    int b;
    unsigned int x[] = {0x10};

    a = *x;
    b = &x;

    print(a);
    print(b);
    print(x);

}
```

执行结果说明一切：

```
vagrant@vagrant-ubuntu-raring-64:~/arena$ ./a.out
value is 10
value is f50cef80
value is f50cef80
```

汇编代码也和预期一致：

```
    00008470 <main>:
    8470:   e92d4800    push    {fp, lr}
    8474:   e28db004    add fp, sp, #4
    8478:   e24dd010    sub sp, sp, #16
    847c:   e3a03010    mov r3, #16
    8480:   e50b3010    str r3, [fp, #-16]
    8484:   e51b3010    ldr r3, [fp, #-16]
    8488:   e50b300c    str r3, [fp, #-12]
    848c:   e24b3010    sub r3, fp, #16
    8490:   e50b3008    str r3, [fp, #-8]
    8494:   e51b000c    ldr r0, [fp, #-12]
    8498:   ebffffe9    bl  8444 <print>
    849c:   e51b0008    ldr r0, [fp, #-8]
    84a0:   ebffffe7    bl  8444 <print>
    84a4:   e24b3010    sub r3, fp, #16
    84a8:   e1a00003    mov r0, r3
    84ac:   ebffffe4    bl  8444 <print>
    84b0:   e1a00003    mov r0, r3
    84b4:   e24bd004    sub sp, fp, #4
    84b8:   e8bd8800    pop {fp, pc}
```

那么，同样是对地址（``f()``也是个地址）做解引用(``*``)，为何作用于函数地址，解引用等同于引用？

我的理解是，对于函数地址的解引用，如何和数组等同处理，返回对应地址的内容，即编译出来的机器码，是能够解释 ``(*f)()``的。因为返回的代码被执行后，``pc`` 会自增，然后代码就顺着函数的逻辑执行下去，这个没有问题。所以，``(*f)()`` 等价于 ``f()``，同样等价于 ``(&f)()``。但问题是如何理解 ``(*******f)()``？貌似任意多的解引用作用于函数地址，编译器并不会报错且运行正常，而 ``(&&&f)()`` 编都编不过？

费了好大劲，想花了脑袋都没想明白。求助于stackoverflow，发现有人也有类似的疑问：[How does dereferencing of a function pointer happen?](http://stackoverflow.com/questions/2795575/how-does-dereferencing-of-a-function-pointer-happen)，最佳答案通过lvalue和rvalue的角度去分析，看着很靠谱，值得一读，我这里就不重复了。


## 后记

学语言，如果抱着一颗写编译器的心去学，那么就无敌于天下了。:)

![小宝和爷爷](/assets/img/photos/baby20130711.jpg)