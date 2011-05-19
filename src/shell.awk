# AWK Module system shell - Could be used as a boot strap
# -----------------------------------------------------------------------------
# "THE BEER-WARE LICENSE" (Revision 43) borrowed from FreeBSD's jail.c:
# <tag@cpan.org> wrote this file.  As long as you retain this notice you
# can do whatever you want with this stuff. If we meet some day, and you think
# this stuff is worth it, you can buy me a beer in return.   Scott S. McCoy
# -----------------------------------------------------------------------------

BEGIN {
    # Only the output file separator is SUBSEP.  This translates spaces to
    # non-spaces...the shell won't work for all message types as a result.
    OFS = SUBSEP

    while (--ARGC != 0) {
	arguments = arguments " " ARGV[ARGC]
    }

    command = "exec awk -f kernel.awk " arguments
    command | getline fifo

    print "shell started, using fifo: " fifo
}

$1 == "exit" {
    print "kernel", "exit" >> fifo
    close(command)
    nextfile
}

{
    print "sending command"
    print $1,$2,$3,$4,$5,$6,$7,$8,$9 >> fifo
    fflush(fifo)
}
