
##
# Capture all output from a short running program.
#
# Like Perl's qx() operator, open the program in a pipe and capture all of its
# output as a single string.  The output is returned.
#
# command: The command to run.
function qx (command	,c,input,result) {
    c = "exec " command

    while ((c | getline input) == 1) {
	result = result input
    }

    close(c)

    return result
}

