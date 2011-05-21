# AWK Module system kernel
# -----------------------------------------------------------------------------
# "THE BEER-WARE LICENSE" (Revision 43) borrowed from FreeBSD's jail.c:
# <tag@cpan.org> wrote this file.  As long as you retain this notice you
# can do whatever you want with this stuff. If we meet some day, and you think
# this stuff is worth it, you can buy me a beer in return.   Scott S. McCoy
# -----------------------------------------------------------------------------

BEGIN {
    pathc = split(ENVIRON["AWKPATH"], pathv, /:/)
}

function qx (command	,c,input,result) {
    c = "exec " command

    while ((c | getline input) == 1) {
	result = result input
    }

    close(c)

    return result
}

function mktemp (   tempfile,c) {
    return qx("mktemp")
}

function remove (filename) {
    system("rm " filename)
}

function mkfifo (   tempfile) {
    tempfile = mktemp()
    remove(tempfile)
    system("mkfifo " tempfile)
    return tempfile
}

function readable (file     ,result,x) {
    result = getline x < file
    close(file)

    return result >= 0
}

function find (filename     ,r,i) {
    for (i = 1; i <= pathc; i++) {
        r = pathv[i] "/" filename

        if (readable(r)) {
            return r
        }
    }

    print "error: unable to find file " filename >> "/dev/stderr"
    exit 1
}

function dependencies (filename     ,loaded,input,df,depends) {
    loaded[filename] = 1

    depends = ""

    while ((getline input < filename) > 0) {
        if (input ~ /^#use/) {
            split(input, words, /[\t ][\t ]*/)
            print "loading module " words[2] >> "/dev/stderr"
            df = find(words[2])

            if (loaded[df] != 1) {
                depends = depends " -f " df
                depends = depends dependencies(df, loaded)
            }
        }
    }

    return depends
}

function kernel_message (module, message, a1,a2,a3,a4,a5,a6,a7,a8,a9) {
    printf "kernel->message(\"%s\", \"%s\")\n", module, message >> "/dev/stderr"

    print message,a1,a2,a3,a4,a5,a6,a7,a8,a9 | kernel["process", module]

    # TODO Enable a buffering option...long running programs should be able to
    # be buffered under many circumstances.
    fflush(kernel["process", module])
}

# For now we use awkpath..
function kernel_load (source, name  ,depends,input,words,filename,loaded) {
    filename = find(source)

    if ("" == filename) {
        print "unable to load " name ": " source " not found" >> "/dev/stderr"
        return
    }

    depends = dependencies(filename, loaded)

    kernel["process", name] = \
	  sprintf("exec %s -f module.awk %s -f %s %s", \
                  awk, depends, source, name)

    print "starting module: " kernel["process", name] >> "/dev/stderr"

    kernel_message(name, "init", FILENAME)
}

## Register a listener to an event.
function kernel_listen (source, event, component, handler   ,i) {
    printf "kernel->listen(\"%s\",\"%s\",\"%s\",\"%s\")\n", \
           source, event, component, handler >> "/dev/stderr"

    i = ++kernel["listeners", source, event]

    kernel["listeners", source, event, i, "component"] = component
    kernel["listeners", source, event, i, "handler"]   = handler
}

## Find the given event listener and remove it.
function kernel_clear (source, event, component, handler     ,i,found) {
    printf "kernel->clear(\"%s\",\"%s\",\"%s\",\"%s\")\n", \
           source, event, component, handler >> "/dev/stderr"

    found = 0

    for (i = 1;
         i <= kernel["listeners", source, event];
         i++)
    {
        # If we've found the item we're removing, shift each subsequent element
        # "back" in the list by one element.

        if (found) {
            kernel["listeners", source, event, i - 1, "component"] = \
                  kernel["listeners", source, event, i, "component"]

            kernel["listeners", source, event, i - 1, "handler"] = \
                  kernel["listeners", source, event, i, "handler"]
        }

        if (kernel["listeners", source, event, i, "component"] == component &&
            kernel["listeners", source, event, i, "handler"] == handler)
        {
            delete kernel["listeners", source, event, i, "component"]
            delete kernel["listeners", source, event, i, "handler"]

            found = 1
        }
    }

    kernel["listeners", source, event]--
}

function kernel_publish (source, event, a1,a2,a3,a4,a5,a6,a7,a8,a9  ,i,c,h) {
    printf "kernel->publish(\"%s\", \"%s\", \"%s\")\n", \
           source, event, a1 >> "/dev/stderr"

    for (i = 1;
         i <= kernel["listeners", source, event];
         i++)
    {
        c = kernel["listeners", source, event, i, "component"]
        h = kernel["listeners", source, event, i, "handler"]

        kernel_message(c, h, a1,a2,a3,a4,a5,a6,a7,a8,a9)
    }
}


function kernel_start (	    fifo,tempfile) {
    fifo = mkfifo()

    print fifo
    fflush()

    # Push our own first message so we can start up
    # The "cat" process and pipe create a buffer to prevent deadlock.

    tempfile = mktemp()
    kernel["tempfile"] = tempfile

    print "kernel", "init" > tempfile
    close(tempfile)

    # Background job to send the initialization event
    system(sprintf("cat %s > %s && rm %s &", \
           tempfile, fifo, tempfile))

    # We need to move out two files, cat will send an EOF.
    # Other processes and the like may as well...make sure we keep the stream
    # open...
    ARGV[ARGC++] = fifo
    ARGV[ARGC++] = fifo
}

function kernel_shutdown (component     ,key,kp) {
    printf "kernel->shutdown(\"%s\")\n", component >> "/dev/stderr"

    # Only shut the module down if it hasn't been shutdown already
    if (kernel["process", component]) {
        kernel_message(component, "fini")

        # Clear all listeners this module has, and all listeners to this
        # module.  This is a really ugly routine, the data structure which
        # holds these should be a little nicer.
        for (key in kernel) {
            split(key, kp, SUBSEP)

            if (kp[1] == "listeners") {
                # If it's this component, then terminate the listeners
                # whole-sale
                if (kp[2] == component) {
                    delete kernel[key]
                }

                # Otherwise check and see if this item is the listener, and
                # then attempt to remove it cleanly through the kernel_clear
                # routine.
                if (kp[5] == "component" && kernel[key] == component) {
                    kernel_clear(kp[2], kp[3], \
                                 kernel[key], \
                                 kernel[kp[1], kp[2], kp[3], kp[4], "handler"])
                }
            }
        }

        close(kernel["process", component])
        delete kernel["process", component]
        print "kernel->cleanup()" >> "/dev/stderr"
    }
}

function kernel_exit (  key,kp) {
    # TODO This should be nicer, and it should use a nice little data
    # structure...
    for (key in kernel) {

        split(key, kp, SUBSEP)

        if (kp[1] == "process") {
            kernel_shutdown(kp[2])
	}
    }

    remove(ARGV[ARGC-1])

    exit 0
}

function kernel_init (  i,m,module) {
    m = kernel["modules"]

    for (i = 1; i <= m; i++) {
        module = kernel["modules", i]
        kernel_load(module, module)
    }
}

# When a kernel event happens, prioritize it by not going into the main loop.
"kernel" == $1 {
    if ("publish" == $2) {
        kernel_publish($3, $4, $5,$6,$7,$8,$9,$10,$11,$12,$13,$14)
    }
    else if ("load" == $2) {
	kernel_load($3,$4)
    }
    else if ("listen" == $2) {
	kernel_listen($3,$4,$5,$6)
    }
    else if ("clear" == $2) {
	kernel_clear($3,$4,$5,$6)
    }
    else if ("shutdown" == $2) {
	kernel_shutdown($3)
    }
    else if ("exit" == $2) {
	kernel_exit()
    }
    else if ("init" == $2) {
        kernel_init()
    }
}

"kernel" != $1 {
    if (kernel["process", $1] != "") {
	kernel_message($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11)
    }
    else {
	printf "module %s not loaded\n", $1 >> "/dev/stderr"
    }
}

function kernel_parse_args (	i,modname,m) {
    for (i = 1; i < ARGC; i++) {
	modname = ARGV[i]

	# All initilization modules are singletons
        kernel["modules", ++m] = modname
    }

    kernel["modules"] = m

    ARGC = 1
}

BEGIN {
    FS = OFS = SUBSEP

    awk = "awk"
    kernel_parse_args()
    kernel_start()
}

# We got an "EOF" on the stream, so we need to append a next file..
FNR == 1 {
    print "kernel:nextfile" >> "/dev/stderr"
    ARGV[ARGC++] = FILENAME
}
