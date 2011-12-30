# A simple runawk-style boot strapper.
# -----------------------------------------------------------------------------
# "THE BEER-WARE LICENSE" (Revision 43) borrowed from FreeBSD's jail.c:
# <tag@cpan.org> wrote this file.  As long as you retain this notice you
# can do whatever you want with this stuff. If we meet some day, and you think
# this stuff is worth it, you can buy me a beer in return.   Scott S. McCoy
# -----------------------------------------------------------------------------

# This utility (which can either be bootstrapped by a shell script, called from
# the commandline or used as a dependency) is intended to eliminate the
# duplication in the AMS kernel, by using a run-awk style bootstrapping method.
# This allows the kernel itself to use other parts of the codebase as
# dependencies, and still allows this very dependency handling code to be used
# by the kernel itself.

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

## Parse a file and determine all of it's dependencies, and theirs,
# recursively.
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

    close(filename)

    return depends
}

BEGIN {
    if (ENVIRON["BUILD_COMMAND"]) {
        
    }
}
