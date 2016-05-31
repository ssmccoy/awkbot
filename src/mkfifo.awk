#use mktemp.awk
#use remove.awk

## Create a new (optionally named) fifo.
# Optionally given a fifo name, or otherwise simply a value that evaluates as
# false, either create the fifo of that name in the prior case, or create a new
# one named after a tempfile.  Always attempt to delete the file before
# creating a fifo.
# filename: The name of the fifo to create (optional).
# return: The name of the fifo, if created successfully, or an empty value
# otherwise.
function mkfifo (filename   ,r) {
    if (!filename) {
        filename = mktemp()
    }

    remove(filename)

    r = system("exec mkfifo " filename " 2> /dev/null")

    return (r == 0 ? filename : "")
}
