---
template: slide.jade
title: Systemtap for NGSRX
date: 2014-01-08 20:50
theme: default

---

    # Systemtap for NGSRX
    <br/>
    ### Tyr Chen
    <br/>
    <br/>
    Stay hungry, stay foolish
    2014-01-08


<!--more-->


    <b>Have you ever been driven crazy by the difficult bugs?</b>

    <img src="../../_static/exhausted.jpg" width="800px" />


    ## What is Systemtap

    <br/>

    * A tool to deeply examine a live linux system
    * For complex performance or functional problems
        * You can extract, filter and summarize the data    

    
    ## What's the benifit of Systemtap?

    * Easy way to debug and profile running processes (and kernel)
    * Minimum impact to the processes traced
    * Powerful and reusable scripts
    * Multiple tracers
    <hr/>
    ``Eliminate most of the private images at least upon Dev/QA cycle``


    <section>

    ## How does it work

    ![Systemtap](../../_static/systemtap.jpg)

    <aside class="notes">

    * Load the stp script
    * Compile it to C code
    * Compile it to kernel module
    * Load the kernel module, introduce TRAP (INT3) into the probes
    * (upon quit) Unload the kernel module

    </aside>

    
    ## Example

    ```
    $ sudo stap -v -e 'probe begin{printf("hello world\n"); exit();}'
    Pass 1: parsed user script and 104 library script(s) using 203496virt/31656res/3108shr/29132data kb, in 180usr/20sys/383real ms.
    Pass 2: analyzed script: 1 probe(s), 1 function(s), 0 embed(s), 0 global(s) using 204156virt/32592res/3364shr/29792data kb, in 0usr/0sys/9real ms.
    Pass 3: translated to C into "/tmp/stap565B3A/stap_b0d6ba829a87e91fab80333b3f250e11_924_src.c" using 204288virt/32920res/3668shr/29924data kb, in 10usr/10sys/19real ms.
    Pass 4: compiled C into "stap_b0d6ba829a87e91fab80333b3f250e11_924.ko" in 920usr/190sys/3122real ms.
    Pass 5: starting run.
    hello world
    Pass 5: run completed in 0usr/20sys/345real ms.
    ```


    ## Systemtap Internals - Utrace

    <img src="../../_static/utrace.jpg" style="width: 800px" />


    ## Systemtap Internals - Code injection

    <img src="../../_static/code_inject.jpg" style="width: 800px" />

    </section>


    <section>

    ## Where to probe (1)?

    * begin
    * end
    * timer.jiffies(1000)
    * timer.s(4)
    * timer.ms(200).randomize(50)


    ## Where to probe (2)?

    * kernel.funcion("*@kernel/fork.c:934")
    * kernel.syscall.*
    * kernel.data("SYMBOL_NAME").write (need CONFIG_HAVE_HW_BREAKPOINT)
    * process("flowd").function("flow_process_pkt")
    * process("flowd").statement(0x412930)
    * netdev.receive/netdev.transmit
    


    For a complete list of probes please [visit the doc](http://sourceware.org/systemtap/SystemTap_Beginners_Guide/scripts.html).


    ## Live example - the code

    ```
    global recv, xmit

    probe begin {
      printf("Starting network capture (Ctl-C to end)\n")
    }

    probe netdev.receive {
      recv[dev_name, pid(), execname()] <<< length
    }

    probe netdev.transmit {
      xmit[dev_name, pid(), execname()] <<< length
    }

    probe end {
      printf("\nEnd Capture\n\n")

      printf("Iface Process........ PID.. RcvPktCnt XmtPktCnt\n")

      foreach ([dev, pid, name] in recv) {
        recvcount = @count(recv[dev, pid, name])
        xmitcount = @count(xmit[dev, pid, name])
        printf( "%5s %-15s %-5d %9d %9d\n", dev, name, pid, recvcount, xmitcount )
      }

      delete recv
      delete xmit
    }
    ```


    ## Live Example - the result

    ```
    $ sudo stap net.stp
    Starting network capture (Ctl-C to end)
    ^C
    End Capture

    Iface Process........ PID.. RcvPktCnt XmtPktCnt
     eth2 mongod          1109          1         0
     eth2 swapper/0       0            49         0
    ```

    </section>


    <section>

    ## What to print (1)?

    * tid()
    * pid()
    * uid()
    * execname()
    * cpu()
    * gettimeofday_s()
    * pp(): A string describing the probe point being currently handled. 


    ## What to print (2)?

    * ppfunc(): If known, the the function name in which this probe was placed.
    * $$vars: If available, a pretty-printed listing of all local variables in scope. 
    * print_backtrace(): If possible, print a kernel backtrace. 
    * print_ubacktrace(): If possible, print a user-space backtrace. 
    * thread_indent(): beautiful print.


    for more internal functions, please [visit the doc](http://sourceware.org/systemtap/SystemTap_Beginners_Guide/systemtapscript-handler.html).


    ## Live Example - the code

    ```
    $ cat thread_ident.stp
    probe kernel.function("*@net/socket.c").call
    {
      printf ("%s -> %s\n", thread_indent(1), probefunc())
    }
    probe kernel.function("*@net/socket.c").return
    {
      printf ("%s <- %s\n", thread_indent(-1), probefunc())
    }
    ```


    ## Live Example - the result

    ```
    $ sudo stap thread_ident.stp
         0 sshd(10847): -> sock_aio_read
         6 sshd(10847):  -> sock_aio_read
        11 sshd(10847):   -> alloc_sock_iocb
        16 sshd(10847):   <- alloc_sock_iocb
        40 sshd(10847):  <- sock_aio_read
        45 sshd(10847): <- sock_aio_read
    ```

    </section>


    ## The ``stap`` Commandline

    * ``-d`` to load debug symbol
    * ``-g`` to run (or embed) unsafe C code into the script
    * ``-x`` to attach to a running process
    * ``-c`` to run the process by the stap
    * ``-t`` to collect timing information (for performance purpose)
    * ``-L`` to inspect the code
    * ...


    <section>

    ## How to use stap in NGSRX?

    * As a replacement to ``private build`` which aims to just collect data
    * As a good study source to our code (just like python introspection)
    * As a complement to ``gdb`` for debugging
    * As a complement to ``gperf`` for performance tuning
    * As a complement to ``jellyfish`` for unit testing


    ## How to make stap work in NGSRX?


    ## Approach 1

    * Ships systemtap in the dev/QA envrionment
    * Ships systemtap in the domestic image for Dev/QA cycle
    * Ship it in released image


    ## Approach 2

    Do not ship it in the image, but:

    ```
    > mk jstap-jobs
    ...
    > ls -l ../ship/jstap*
    -rw-r--r--  1 tchen  wheel  442143 Jan  6 17:08 ../ship/jstap-i386-12.1I20140107_0107_tchen-signed.tgz
    -rw-r--r--  1 tchen  wheel  411014 Jan  6 17:08 ../ship/jstap-i386-12.1I20140107_0107_tchen.tgz
    -rw-r--r--  1 tchen  wheel      41 Jan  6 17:08 ../ship/jstap-i386-12.1I20140107_0107_tchen.tgz.sha1
    ```

    ```
    cli> request system software add jstap-i386-12.1I20140107_0107_tchen-signed.tgz
    ```

    </section>


    <section>

    # DEMOs


    ## Live Example with flowd

    ```
    (poc)tchen@ngsrx-build04:~/ngsrx/new/obj_sa/sdk/lib/fandf$ 
    sudo stap -d flowd -x 32525 ~/arena/stap/flow_fn_parser.stp
     0x412930 : flowd_parser+0x0/0x88 [...volume/junosv-storage02/tchen/new/obj_sa/sdk/lib/fandf/flowd]
     0x79425a : parser_sub_parse_end_of_line+0x6a/0x87 [...volume/junosv-storage02/tchen/new/obj_sa/sdk/lib/fandf/flowd]
     0x79069f : parser_parse_node+0xfe/0x105 [...volume/junosv-storage02/tchen/new/obj_sa/sdk/lib/fandf/flowd]
     0x7922ea : parser_parse_words+0x3c3/0x53a [...volume/junosv-storage02/tchen/new/obj_sa/sdk/lib/fandf/flowd]
     0x7924c4 : parser_parse_string+0x63/0x6b [...volume/junosv-storage02/tchen/new/obj_sa/sdk/lib/fandf/flowd]
     0x78f540 : editor_read_and_parse+0xa6/0xd4 [...volume/junosv-storage02/tchen/new/obj_sa/sdk/lib/fandf/flowd]
     0x795660 : system_console_create+0x30f/0x3bc [...volume/junosv-storage02/tchen/new/obj_sa/sdk/lib/fandf/flowd]
     0x59c2c1 : console_server+0x2d/0x2f [...volume/junosv-storage02/tchen/new/obj_sa/sdk/lib/fandf/flowd]
     0x59c6cd : vty_daemon+0x385/0x3e3 [...volume/junosv-storage02/tchen/new/obj_sa/sdk/lib/fandf/flowd]
     0x7bfa0e : thread_suicide+0x0/0x7b [...volume/junosv-storage02/tchen/new/obj_sa/sdk/lib/fandf/flowd]
    config={.buffer_area="<unknown>", .buffer_size=9892429799577096428, .buffer_end=-1958154123, .security_level=-1177104635, .words=[...], .positions=[...], .word_count=-55163, .tree_top=0x418908b48ff, .stack=[...], .current_stack_level=-1914419829, .stop_at_index=-1065156092, .current_word="<unknown>", .current_word_index=-947304296, .current_level=0x7d8348e845894800, .current_result=0xbbd818bf147500e8, .current_crumbs=0x71e800000000b800, .match=0x10be9fffffc, .possible_match=0x10508d48e8458b48, .expand_resu
    ```

    </section>


    ## Limitations

    * Inline functions
    * Systemtap itself and its friends (utrace, ...)
    * Initialization code


    ## References

    * [Improving the debugability with systemtap](../research/improving-debugability.html)
    * [Systemtap online document](http://sourceware.org/systemtap/documentation.html)


    ## Thanks - questions?


