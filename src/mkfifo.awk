

## Wrapper for mkfifo(1p)
# filename: The name of the fifo to create
# return: a true value if the command succeeded, a false value otherwise.
function mkfifo (filename   ,r) {
    r = system("exec mkfifo " filename " 2> /dev/null")

    return r == 0
}
