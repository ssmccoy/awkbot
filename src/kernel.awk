# AWK Module system kernel
# -----------------------------------------------------------------------------
# "THE BEER-WARE LICENSE" (Revision 43) borrowed from FreeBSD's jail.c:
# <tag@cpan.org> wrote this file.  As long as you retain this notice you
# can do whatever you want with this stuff. If we meet some day, and you think
# this stuff is worth it, you can buy me a beer in return.   Scott S. McCoy
# -----------------------------------------------------------------------------

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

function kernel_message (module, message, a1,a2,a3,a4,a5,a6,a7,a8,a9) {
    printf "[%s %s]\n", module, message >> "/dev/stderr"

    print message,a1,a2,a3,a4,a5,a6,a7,a8,a9 | kernel["process", module]

    # TODO Enable a buffering option...long running programs should be able to
    # be buffered under many circumstances.
    fflush(kernel["process", module])
}

# For now we use awkpath..
function kernel_load (source, name  ,modules,input,words) {
    if ("" == name) {
        name = kernel["objects"]++
    }

    while ((getline input < source) > 0) {
        if (input ~ /#use/) {
            split(input, words, /[\t ][\t ]*/)
            modules = modules " -f " words[2]
        }
    }

    kernel["process", name] = \
	  sprintf("exec %s -f module.awk %s -f %s %s", \
                  awk, modules, source, name)

    kernel_message(name, "init", FILENAME)
}

## Register a listener to an event.
function kernel_listen (source, event, component, handler   ,i) {
    i = kernel["listeners", source, event]

    kernel["listeners", source, event, i, "component"] = component
    kernel["listeners", source, event, i, "handler"]   = component
}

## Find the given event listener and remove it.
function kernel_clear (source, event, component, handler     ,i,found) {
    found = 0

    for (i = kernel["listeners", source, event]; 
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
}

function kernel_publish (source, event, a1,a2,a3,a4,a5,a6,a7,a8,a9  ,i,c,h) {
    for (i = kernel["listeners", source, event]; 
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

function kernel_shutdown (component) {
    kernel_send(component, "fini")

    close(kernel["process", component])
    delete kernel["process", component]
}

function kernel_exit () {
    # TODO This should be nicer, and it should use a nice little data
    # structure...
    for (key in kernel) {
	if (substr(key, 0, 7) == "process") {
	    close(kernel[key])
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
	kernel_register($3,$4,$5,$6)
    }
    else if ("clear" == $2) {
	kernel_register($3,$4,$5,$6)
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
