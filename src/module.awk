# A module system for POSIX-Compatible AWK processes.
# -----------------------------------------------------------------------------
# "THE BEER-WARE LICENSE" (Revision 43) borrowed from FreeBSD's jail.c:
# <tag@cpan.org> wrote this file.  As long as you retain this notice you
# can do whatever you want with this stuff. If we meet some day, and you think
# this stuff is worth it, you can buy me a beer in return.   Scott S. McCoy
# -----------------------------------------------------------------------------

function kernel_send (component, operation, a1,a2,a3,a4,a5,a6,a7,a8,a9,o,f) {
    # There is no reasonable way to do this iteratively.  The simplicity of awk
    # is occasionally paramount.
    # This is ESCAPE, see UNESCAPE for the converse.
    gsub("\\",   "\\0x5C", a1)
    gsub("\n",   "\\0x0A", a1)
    gsub(SUBSEP, "\\0x01", a1)

    gsub("\\",   "\\0x5C", a2)
    gsub("\n",   "\\0x0A", a2)
    gsub(SUBSEP, "\\0x01", a2)

    gsub("\\",   "\\0x5C", a3)
    gsub("\n",   "\\0x0A", a3)
    gsub(SUBSEP, "\\0x01", a3)

    gsub("\\",   "\\0x5C", a4)
    gsub("\n",   "\\0x0A", a4)
    gsub(SUBSEP, "\\0x01", a4)

    gsub("\\",   "\\0x5C", a5)
    gsub("\n",   "\\0x0A", a5)
    gsub(SUBSEP, "\\0x01", a5)

    gsub("\\",   "\\0x5C", a6)
    gsub("\n",   "\\0x0A", a6)
    gsub(SUBSEP, "\\0x01", a6)

    gsub("\\",   "\\0x5C", a7)
    gsub("\n",   "\\0x0A", a7)
    gsub(SUBSEP, "\\0x01", a7)

    gsub("\\",   "\\0x5C", a8)
    gsub("\n",   "\\0x0A", a8)
    gsub(SUBSEP, "\\0x01", a8)

    gsub("\\",   "\\0x5C", a9)
    gsub("\n",   "\\0x0A", a9)
    gsub(SUBSEP, "\\0x01", a9)

    gsub("\\",   "\\0x5C", o)
    gsub("\n",   "\\0x0A", o)
    gsub(SUBSEP, "\\0x01", o)

    gsub("\\",   "\\0x5C", f)
    gsub("\n",   "\\0x0A", f)
    gsub(SUBSEP, "\\0x01", f)

    if (!_k_pipename) {
        printf "%s has no init", this >> "/dev/stderr"
    }

    print component, operation, a1,a2,a3,a4,a5,a6,a7,a8,a9,o,f >> _k_pipename
    fflush(_k_pipename)
}

function kernel_load (source, name) {
    kernel_send("kernel", "load", source, name)
}

function kernel_listen (component, event, handler) {
    if ("" == handler) {
        handler = event
    }

    kernel_send("kernel", "listen", component, event, this, handler)
}

function kernel_clear (component, event, handler) {
    kernel_send("kernel", "clear", component, event, this, handler)
}

function kernel_shutdown () {
    kernel_send("kernel", "shutdown", this)
}

function kernel_publish (event, a1,a2,a3,a4,a5,a6,a7,a8,a9) {
    kernel_send("kernel", "publish", this, event, a1,a2,a3,a4,a5,a6,a7,a8,a9)
}

BEGIN {
    if (ARGC != 3) {
        this = ARGV[--ARGC]
    }
    else {
        print "initlization error: expected pipe and component name" >> \
            "/dev/stderr"

        exit 1
    }

    # Make the field separators SUBSEP so spaces don't blow up in message
    # arguments.  This means modules have to be coherent of that fact...
    FS = OFS = SUBSEP
}

# UNESCAPE each argument of the input.
{
    # I use \0x5C for "\" to avoid injection of "\0x01" into the stream.  If
    # someone attempted, it will appear as \0x5C0x01 and properly be replaced
    # by \0x01.
    for (i = 1; i <= NF; i++) {
	gsub("\\\\0x01", SUBSEP, $i)
	gsub("\\\\0x0A", "\n",   $i)
	gsub("\\\\0x5C", "\\",   $i)
    }
}

"init" == $1 {
    _k_pipename = $2
}
