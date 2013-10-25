---
layout: slide
theme: default
title: Python & Django
date: 2013-07-10 15:14
comments: true
published: true
tags: []
---

    # Python & Django
    ### Tyr Chen
    2013-07-10


<!--more-->


    ## What is it about?

    * Python Basics
    * Metaprogramming
    * Django Basics
    * Misc

    
    # Python Basics


    <section>
    ## Data Structure


    ## integer

    ```
    # basic
    In [1]: a = 123456789123456789123456789 # any big number

    In [287]: dir(a)
    Out[287]:
    ['__abs__',
     '__add__',
     '__and__',
     '__class__',
     '__cmp__',
     '__coerce__',
     '__delattr__',
     '__div__',
     '__divmod__',
     '__doc__',
     '__float__',
     '__floordiv__',
     '__format__',
     '__getattribute__',
     '__getnewargs__',
     '__hash__',
     '__hex__',
     '__index__',
     '__init__',
     '__int__',
     '__invert__',
     '__long__',
     '__lshift__',
     '__mod__',
     '__mul__',
     '__neg__',
     '__new__',
     '__nonzero__',
     '__oct__',
     '__or__',
     '__pos__',
     '__pow__',
     '__radd__',
     '__rand__',
     '__rdiv__',
     '__rdivmod__',
     '__reduce__',
     '__reduce_ex__',
     '__repr__',
     '__rfloordiv__',
     '__rlshift__',
     '__rmod__',
     '__rmul__',
     '__ror__',
     '__rpow__',
     '__rrshift__',
     '__rshift__',
     '__rsub__',
     '__rtruediv__',
     '__rxor__',
     '__setattr__',
     '__sizeof__',
     '__str__',
     '__sub__',
     '__subclasshook__',
     '__truediv__',
     '__trunc__',
     '__xor__',
     'bit_length',
     'conjugate',
     'denominator',
     'imag',
     'numerator',
     'real']

    In [2]: pi = 3.1415926
    ```


    ## list

    ```
    In [27]: l = [1,2,3,4,5]

    In [28]: l
    Out[28]: [1, 2, 3, 4, 5]

    In [273]: len(l)
    Out[273]: 5

    In [274]: l.append(6)

    In [275]: l
    Out[275]: [1, 2, 3, 4, 5, 6]

    In [276]: l[3]
    Out[276]: 4

    In [277]: map(lambda x: x*2, l)
    Out[277]: [2, 4, 6, 8, 10, 12]

    In [279]: reduce(lambda x,y: x+y, l)
    Out[279]: 21
    ```


    ## dict

    ```
    In [29]: point = {"x": 10, "y": -20}

    In [30]: point["x"]
    Out[30]: 10

    In [31]: point["y"]
    Out[31]: -20

    In [281]: point.keys()
    Out[281]: ['y', 'x']

    In [282]: point.has_key('x')
    Out[282]: True

    In [283]: point.items()
    Out[283]: [('y', -20), ('x', 10)]

    In [32]: s = "This is a string"

    In [33]: s.split(' ')
    Out[33]: ['This', 'is', 'a', 'string']

    In [36]: ' '.join(['This', 'is', 'a', 'string'])
    Out[36]: 'This is a string'
    ```

    </section>


    <section>

    ## Function and control flow


    ## Function Basics

    ```
    In [3]: def double(x):
       ...:     return x*2
       ...:

    In [4]: double(pi)
    Out[4]: 6.2831852

    In [11]: def max(a, b):
       ....:     return a if a > b else b # inline if/else
       ....:

    In [15]: def min(a, b):
       ....:     if a < b: # normal if else
       ....:         return a
       ....:     else:
       ....:         return b
       ....:

    In [12]: def avg(l):
       ....:     total = sum(l) # function can be used before getting defined
       ....:     return total/len(l)
       ....:

    In [13]: def sum(l):
       ....:     total = 0
       ....:     for item in l: # foreach style forloop
       ....:         total += item
       ....:     return total
       ....:

    In [14]: avg([1,2,3])
    Out[14]: 2

    In [16]: def triple(l):
       ....:     return map(lambda x: x*3, l) # anonymous function 
       ....:

    In [17]: triple([1,2,3])
    Out[17]: [3, 6, 9]
    ```


    ## Higher Order Function

    ```
    In [22]: def multiple(y):  # function can return function (higher order function)
       ....:     def f(x):
       ....:         return x * y
       ....:     return f
       ....:

    In [23]: double = multiple(2)

    In [24]: double(10)
    Out[24]: 20

    In [25]: triple = multiple(3)

    In [26]: triple(10)
    Out[26]: 30
    ```


    ## Generator

    ```
    In [40]: def fabonacci(): # generator
       ....:     a, b = 1, 2
       ....:     while True:
       ....:         a, b = b, a+b
       ....:         yield b
       ....:

    In [56]: f = fabonacci()

    In [57]: f.next()
    Out[57]: 3

    In [58]: f.next()
    Out[58]: 5

    In [59]: f.next()
    Out[59]: 8

    In [60]: f.next()
    Out[60]: 13

    In [61]: f.next()
    Out[61]: 21       
    ```

    </section>


    <section>

    ## OOP


    ## OOP Basics

    ```
    In [8]: class Circle:
    ....:       def __init__(self, r):
    ....:           self.r = r
    ....:       def area(self):
    ....:           return 3.14159 * self.r * self.r
    ....:

    In [9]: c = Circle(10)

    In [10]: c.area()
    Out[10]: 314.159
    ```


    ## Operator override

    ```
    In [65]: class Iterable: # make object work like a list
       ....:     def __iter__(self):
       ....:         return self
       ....:     def next(self):
       ....:         if self.has_next():
       ....:             return self.next_value()
       ....:         else:
       ....:             raise StopIteration
       ....:     def __init__(self, items):
       ....:         self.items = items
       ....:         self.cur = 0
       ....:     def has_next(self):
       ....:         return self.cur < len(self.items)
       ....:     def next_value(self):
       ....:         value = self.items[self.cur]
       ....:         self.cur += 1
       ....:         return value
    
    In [67]: i = Iterable([1,2,3,4])

    In [68]: for item in i:
       ....:     print item
       ....:
    1
    2
    3
    4       

    In [69]: class Indexable:
       ....:     def __getitem__(self, index):
       ....:         return index * 2
       ....:

    In [70]: i = Indexable()

    In [71]: i[3]
    Out[71]: 6

    In [72]: i["Hello"]
    Out[72]: 'HelloHello'
    ```


    ## Inheritance
    
    Python do not stop you from multiple inheritance, but single inheritance is recommended

    ```
    In [73]: class A(Indexable, Iterable): # here Indexable is a mixin, actually
       ....:     pass
       ....:

    In [74]: a = A([1,2,3,4])

    In [75]: a[2]
    Out[75]: 4

    In [76]: map(lambda x:x, a)
    Out[76]: [1, 2, 3, 4]
    ```

    </section>


    <section>
    
    ## Metaprogramming
    

    __What is class?__


    __Class is the template of creating objects__

    <br/>
    which have different states but share with same structure and behavior


    ## old and new style classes
    
    ```
    # old style class
    In [1]: class X:
       ...:     pass
   
    In [2]:

    In [2]: x = X()

    In [3]: type(x)
    Out[3]: instance

    In [4]: type(type(x))
    Out[4]: type

    In [6]: type(X)
    Out[6]: classobj

    In [7]: type(type(X))
    Out[7]: type

    # new style class
    In [8]: class Y(object):
       ...:     pass
       ...:

    In [9]: y = Y()

    In [10]: type(Y)
    Out[10]: type

    In [11]: type(y)
    Out[11]: __main__.Y

    In [12]: type(type(y))
    Out[12]: type
    ```


    ## Crafting class

    ```
    class Animal(object):
        can_fly = False

        def flee(self):
            if self.can_fly:
                print "Fly..."
            else:
                print "Run..."

    class Swimmable(object):
        def swim(self):
            print "I'm swimming"

    class Duck(Animal, Swimmable):
        can_fly = True

        def say(self):
            print "Gaga..."

    In [22]: d = Duck()

    In [23]: d.flee()
    Fly...

    In [24]: d.say()
    Gaga...

    In [25]: d.swim()
    I'm swimming
    ```


    ## Craft the class on the fly

    ```
    In [50]: Duck1 = type("Duck1", (Animal, Swimmable), {'can_fly': True, 'say': say})

    In [51]: d1 = Duck1()

    In [52]: d1.say()
    Gaga...

    In [53]: d1.can_fly
    Out[53]: True

    In [54]: d1.flee()
    Fly...

    In [55]: d1.swim()
    I'm swimming
    ```
    

    ## Method mssing

    Method mssing could be used to dynamically add attributes that are in common.

    ```
    In [39]: class Y(object):
       ....:     point = (0, 0)
       ....:     def __getattr__(self, attr):
       ....:         def f(*args, **kwargs):
       ....:             return "%s, %s" % (args, kwargs)
       ....:         print "%s is missing" % attr
       ....:         return f
       ....:

    In [42]: y.point
    Out[42]: (0, 0)

    In [44]: y.hello("a", "b")
    hello is missing
    Out[44]: "('a', 'b'), {}"

    In [45]: y.asdf
    asdf is missing
    Out[45]: <function __main__.f>
    ```


    ## Method missing real case

    ```
    # code from https://github.com/michaelliao/sinaweibopy
    class APIClient(object):
        ...

        def __getattr__(self, attr):
            return _Callable(self, attr)

    class _Executable(object):

        def __init__(self, client, method, path):
            self._client = client
            self._method = method
            self._path = path

        def __call__(self, **kw):
            method = _METHOD_MAP[self._method]
            if method==_HTTP_POST and 'pic' in kw:
                method = _HTTP_UPLOAD
            return _http_call('%s%s.json' % (self._client.api_url, self._path), method, self._client.access_token, **kw)

        def __str__(self):
            return '_Executable (%s %s)' % (self._method, self._path)

        __repr__ = __str__

    class _Callable(object):

        def __init__(self, client, name):
            self._client = client
            self._name = name

        def __getattr__(self, attr):
            if attr=='get':
                return _Executable(self._client, 'GET', self._name)
            if attr=='post':
                return _Executable(self._client, 'POST', self._name)
            name = '%s/%s' % (self._name, attr)
            return _Callable(self._client, name)

        def __str__(self):
            return '_Callable (%s)' % self._name

        __repr__ = __str__
    
    # use it
    client = APIClient(app_key=YOUR_APP_KEY, app_secret=YOUR_APP_SECRET,
                   redirect_uri=YOUR_CALLBACK_URL)

    print client.statuses.user_timeline.get()
    print client.statuses.update.post(status=u'test plain weibo')
    print client.statuses.upload.post(status=u'test weibo with picture',
                                  pic=open('/Users/michael/test.png'))
    ```
    
    
    ## Metaclass

    <br/>
    A metaclass is a class whose instances are classes. 

    It defines the behavior of certain classes and their instances.


    ## Adding classmethod automatically
    
    ```
    $ cat metatest.py
    import random

    class MetaAutoProperty(type):
        def __init__(cls, name, bases, attrs):
            super(MetaAutoProperty, cls).__init__(name, bases, attrs)
            for key in attrs:
                if not key.startswith('_') and not hasattr(attrs[key], '__call__'):
                    new_key = 'find_by_%s' % key
                    setattr(cls, new_key, classmethod(lambda c, value: "look up %s...find %d records"
                            % (value, random.randint(0, 10))))

    class AutoProperty(object):
        __metaclass__ = MetaAutoProperty

    class User(AutoProperty):
        name = "Tyr"
        _password = "won't tell you"
        title = "Software Engineer"

        def change_password(self, password):
            self._password = password

    if __name__ == '__main__':
        print User.find_by_name("Hello World")
        print User.find_by_title("MTS")

    $ python  ./metatest.py
    look up Hello World...find 8 records
    look up MTS...find 6 records
    ```

    </section>
    

    # Django Basics


    # Misc


    # Thanks

    <br/>
    **Learning by doing,**

    **and learning by shipping.**

    <br/><hr/>
    *Every engineer should use MAC*