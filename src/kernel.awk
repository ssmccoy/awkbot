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
    print message,a1,a2,a3,a4,a5,a6,a7,a8,a9 | kernel["process", module]
}

# For now we use awkpath..
function kernel_load (source, name) {
    if ("" == name) {
	name = kernel["objects"]++
    }

    printf "loading: %s\n", name >> "/dev/stderr"

    kernel["process", name] = \
	  sprintf("exec %s -f module.awk -f %s %s", awk, source, name)

    kernel_message(name, "init", FILENAME)
}

function kernel_start (	    fifo) {
    print "kernel_start()" >> "/dev/stderr"
    fifo = mkfifo()

    print fifo
    fflush()

    ARGV[ARGC++] = fifo
}

function kernel_shutdown (name) {
    close( kernel["process", name])
    delete kernel["process", name]
}

function kernel_exit () {
    # TODO This should be nicer, and it should use a nice little data
    # structure...
    for (key in kernel) {
	if (substr(key, 0, 7) == "process") {
	}
    }
}

# When a kernel event happens, prioritize it by not going into the main loop.
"kernel" == $1 {
    if ("load" == $2) {
	kernel_load($3,$4)
    }
    else if ("register" == $2) {
	kernel_register($3)
    }
    else if ("shutdown" == $2) {
	kernel_shutdown()
    }
    else if ("exit" == $2) {
	kernel_exit()
    }

    next
}


{
    if (kernel["process", $1] != "") {
	kernel_message($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11)
    }
    else {
	printf "module %s not loaded\n", $1 >> "/dev/stderr"
    }
}

function kernel_parse_args (	i,modname) {
    for (i = 1; i < ARGC; i++) {
	modname = ARGV[i]

	# All initilization modules are singletons
	kernel_load(modname, modname)
    }

    ARGC = 1
}

BEGIN {
    FS = OFS = SUBSEP

    awk = "awk"
    kernel_parse_args()
    kernel_start()

    print "kernel started" >> "/dev/stderr"
}
