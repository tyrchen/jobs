---
template: slide.jade
theme: beige
title: the tao of programming
date: 2013-07-01 21:14
comments: true
transition: concave
published: true
tags: []
---

    # The Tao of Programming
    ### Brought to you by Tyr Chen
    2013-07-01


<!--more-->


    ## What is it about?

    * Principles
    * Paradigms
    * Methodology
    * Patterns


    ## What is it not about?
    * Programming Languages
    * Frameworks or Libraries
    * Coding techniques


    ## Principles
    * Don't Repeat Yourself (DRY)
    * Open/Closed
    * Separation of Concerns (SoC)
    * Inversion of Control (IoC)
    * Convention over Configuration (CoC)
    * Encapsulation
    * Indirection


    ## Don't Repeat Yourself!

    * Hardware session installation (SoS)
    * octeon_pthread_init()


    <section>

    ## Open/Closed Principle (OCP)

    <br/>
    *Software entities should be open for extension, but closed for modification.*


    Let's rewrite ``octeon_pthread_init()``:
    
    ```
    def octeon_pthread_init(configuration='/etc/flowd.conf'):
        f = open(configuration)
        conf = json.load(f)
        cores = conf['cores']
        for core in cores:
            callback = pthread_callbacks[core['callback']]
            id = core['id']
            stack_size = core['stack_size']
            stack = stack_create(stack_size)
            name = core['name']
            
            # pre hook
            pthread_pre_init(core)
            
            pthread_create(callback, id, name, stack, stack_size)
            
            # post hook - e.g. UTM initialization
            pthread_post_init(core)
    
    # here comes the file content
    {
        "cores": [
            {
                "name": "TX",
                "id": 1,
                "stack_size": 128000,
                "callback": "PTHREAD_CALLBACK_TX"
            }, {
                "name": "LBT",
                "id": 2,
                "stack_size": 256000,
                "callback": "PTHREAD_CALLBACK_LBT"
            }
        ]
    }
    ```

    *This is also an example of SoC*

    </section>


    ## Separation of Concerns (SoC)

    <br/>

    *separation of concerns is the process of breaking a computer program into distinct features that overlap in functionality as little as possible.*

    
    <section>

    ## Inversion of Control (IoC)
    
    <br/>
    *Don't call me, let us call you.*


    ```
    # in settings
    middlewares = [Authenticator, Logger, ...]
    
    # in your class
    Class Logger(MiddleWare):
        def handle_request(request):
            pass

        def handle_response(response):
            pass
    ```

    </section>


    ## Convention over Configuration

    *Aka coding by convention - seeks to decrease the number of decisions that developers need to make, gaining simplicity, but not necessarily losing flexibility.*


    <section>

    ## Encapsulation


    ```
    // code from linux kernel...
    struct device 
    {

      /*
       * This is the first field of the "visible" part of this structure
       * (i.e. as seen by users in the "Space.c" file).  It is the name
       * the interface.
       */
      char                    *name;

      /* I/O specific fields                                           */
      unsigned long           rmem_end;        /* shmem "recv" end     */
      unsigned long           rmem_start;      /* shmem "recv" start   */
      unsigned long           mem_end;         /* shared mem end       */
      unsigned long           mem_start;       /* shared mem start     */
      unsigned long           base_addr;       /* device I/O address   */
      unsigned char           irq;             /* device IRQ number    */

      /* Low-level status flags. */
      volatile unsigned char  start,           /* start an operation   */
                              interrupt;       /* interrupt arrived    */
      unsigned long           tbusy;           /* transmitter busy     */
      struct device           *next;

      /* The device initialization function. Called only once.         */
      int                     (*init)(struct device *dev);

      /* Some hardware also needs these fields, but they are not part of
         the usual set specified in Space.c. */
      unsigned char           if_port;         /* Selectable AUI,TP,   */
      unsigned char           dma;             /* DMA channel          */

      struct enet_statistics* (*get_stats)(struct device *dev);

      /*
       * This marks the end of the "visible" part of the structure. All
       * fields hereafter are internal to the system, and may change at
       * will (read: may be cleaned up at will).
       */

      /* These may be needed for future network-power-down code.       */
      unsigned long           trans_start;     /* Time (jiffies) of 
                                                  last transmit        */
      unsigned long           last_rx;         /* Time of last Rx      */
      unsigned short          flags;           /* interface flags (BSD)*/
      unsigned short          family;          /* address family ID    */
      unsigned short          metric;          /* routing metric       */
      unsigned short          mtu;             /* MTU value            */
      unsigned short          type;            /* hardware type        */
      unsigned short          hard_header_len; /* hardware hdr len     */
      void                    *priv;           /* private data         */

      /* Interface address info. */
      unsigned char           broadcast[MAX_ADDR_LEN];
      unsigned char           pad;               
      unsigned char           dev_addr[MAX_ADDR_LEN];  
      unsigned char           addr_len;        /* hardware addr len    */
      unsigned long           pa_addr;         /* protocol address     */
      unsigned long           pa_brdaddr;      /* protocol broadcast addr*/
      unsigned long           pa_dstaddr;      /* protocol P-P other addr*/
      unsigned long           pa_mask;         /* protocol netmask     */
      unsigned short          pa_alen;         /* protocol address len */

      struct dev_mc_list      *mc_list;        /* M'cast mac addrs     */
      int                     mc_count;        /* No installed mcasts  */
      
      struct ip_mc_list       *ip_mc_list;     /* IP m'cast filter chain */
      __u32                   tx_queue_len;    /* Max frames per queue   */
        
      /* For load balancing driver pair support */
      unsigned long           pkt_queue;       /* Packets queued       */
      struct device           *slave;          /* Slave device         */
      struct net_alias_info   *alias_info;     /* main dev alias info  */
      struct net_alias        *my_alias;       /* alias devs           */
      
      /* Pointer to the interface buffers. */
      struct sk_buff_head     buffs[DEV_NUMBUFFS];

      /* Pointers to interface service routines. */
      int                     (*open)(struct device *dev);
      int                     (*stop)(struct device *dev);
      int                     (*hard_start_xmit) (struct sk_buff *skb,
                                                  struct device *dev);
      int                     (*hard_header) (struct sk_buff *skb,
                                              struct device *dev,
                                              unsigned short type,
                                              void *daddr,
                                              void *saddr,
                                              unsigned len);
      int                     (*rebuild_header)(void *eth, 
                                              struct device *dev,
                                              unsigned long raddr,
                                              struct sk_buff *skb);
      void                    (*set_multicast_list)(struct device *dev);
      int                     (*set_mac_address)(struct device *dev,
                                              void *addr);
      int                     (*do_ioctl)(struct device *dev, 
                                              struct ifreq *ifr,
                                              int cmd);
      int                     (*set_config)(struct device *dev,
                                              struct ifmap *map);
      void                    (*header_cache_bind)(struct hh_cache **hhp,
                                              struct device *dev, 
                                              unsigned short htype,
                                              __u32 daddr);
      void                    (*header_cache_update)(struct hh_cache *hh,
                                              struct device *dev,
                                              unsigned char *  haddr);
      int                     (*change_mtu)(struct device *dev,
                                              int new_mtu);
      struct iw_statistics*   (*get_wireless_stats)(struct device *dev);
    };
    ```

    </section>


    <section>

    ## Indirection

    <br/>
    *All problems in computer science can be solved by another level of indirection.*


    application
    <hr/>
    __OS__
    <hr/>
    bare metal


    application
    <hr/>
    __Virtual Memory__
    <hr/>
    physical memory


    OS
    <hr/>
    __Virtual Machine__
    <hr/>
    bare metal/OS


    real datagram
    <hr/>
    __Tunnel__
    <hr/>
    transport channel


    ifstate
    <hr/>
    __Proxy Peer__  
    <hr/>
    ifstate consumer

    </section>


    ## Summary - what to bring back
    <br/>
    *DRY, OCP, SoC, IoC, CoC, Encapsulation, Indirection...*


    ## Paradigms
    * Generic Programming (GP)
    * Meta Programming & DSL

    
    <section>

    ## Generic Programming (GP)
    
    <br/>

    *Decouple algorithm with data structure, generalize the data structure used by algorithm so that the algorithm could be reused broadly.*
    

    __What's your intuition on GP?__


    *Yes in C++ we have this weired thing called template, and a library called __STL__... *

    <br/>
    ```
    template <typename T>
    T max(T a, T b) {
        return (a > b) ? a : b;
    }
    ```


    __Well, what we're talking is more than that...__


    ### Basic coding tests
    1. Randomly pick up 10 numbers from an array, sum up the primes.
    2. Given company directory, find female engineers then raise their salary by 10%.
    3. In CLI if user input a keyword which doesn't exist, print error message.


    __How do you abstract the algorithm?__


    ```
    // C++
    template <typename Iterator, typename Filter, typename Action>
    void process(Iterator begin, Iterator end, Filter test, Action action) {
        for (; begin <= end; begin++) {
            if (test(*begin)) action(*begin);
        }
    }
    ```
    
    ```
    # Python
    def process(l, test, action):
        def f(x):
            return action(x) if test(x) else None

        return filter(None, map(f, l))
    ```

    ```
    %% Erlang
    process(L, test, action) ->
        [action(X) || X <- L, test(X) =:= true].
    ```

    </section>


    <section>

    ## Meta Programming & DSL

    <br/>

    *a programmed system begins to program itself.*


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

    </section>


    ## Summary - what to bring back
    
    <br/>

    * GP: algorithm, container, iterator
    * MP: program to write program itself


    ## Methodology
    * Object Oriented Programming (OOP)
    * Aspect Oriented Programming (AOP)
    * Functional Programming (FP)


    ## Object Oriented Programming (OOP)


    <section>

    ## Aspect Oriented Programming (AOP)


    ```
    # normally if we want to authenticate user in a view
    def user_view(request, *args, **kwargs):
      if request.user.is_authenticated():
        return HttpRequestRedirect('/login/')

      user = request.user
      profile = user.get_profile()

      varialbes = RequestContext(request, {
        'user': user,
        'profile': profile,
      })

      return render_to_response(...)

    # AOP for authenticate a user in a view
    @login_required
    def user_view(request, *args, **kwargs):
      user = request.user
      profile = user.get_profile()

      varialbes = RequestContext(request, {
        'user': user,
        'profile': profile,
      })

      return render_to_response(...)
    ```

    </section>


    ## Functional Programming (FP)

    ```
    % Erlang
    qsort([]) -> [];
    qsort([Pivot|T]) ->
      qsort([X || X <- T, X < Pivot])
      ++ [Pivot] ++
      qsort([X || X <- T, X >= Pivot]).
    ```


    ## Summary - what to bring back
    
    <br/>

    * OOP - focus on data, then algorithm operated on data
    * AOP - focus on core logic, moving concerns out
    * FP  - no side effect, more abstracted, and elegant


    ## Patterns
    * Observer (Pub/Sub)
    * Chain of Responsibility
    * Strategy
    * ...


    ## Observer (Pub/Sub)

    <br/>
    *event notification, linux kernel notifier chain, etc.*


    ## Chain of Responsibility
    
    <br/>
    *jexec nexthop, flow vector processing are typical use cases.*


    ## Strategy

    <br/>
    *the strategy pattern defines a family of algorithms, encapsulates each one, and makes them interchangeable.*
    
    *3DES/AES, etc.*


    ## In summary - Zen of Coding

    ```
    >>> import this
    ```
    
    ```
    Beautiful is better than ugly.
    Explicit is better than implicit.

    Simple is better than complex.
    Complex is better than complicated.

    Flat is better than nested.
    Sparse is better than dense.

    Readability counts.

    Special cases are not special enough to break the rules.
    Although practicality beats purity.

    Errors should never pass silently.
    Unless explicitly silenced.

    In the face of ambiguity, refuse the temptation to guess.

    There should be one - and preferably only one - obvious way to do it.
    Although that way may not be obvious at first unless you are Dutch.

    Now is better than never.
    Although never is often better than *right* now.

    If the implementation is hard to explain, it is a bad idea.
    If the implementation is easy to explain, it may be a good idea.

    Namespaces are one honking great idea -- let us do more of those!   
    ```


    # Thanks

    <br/>
    **Learning by doing,**

    **and learning by shipping.**

    <br/><hr/>
    *Every engineer should use MAC*