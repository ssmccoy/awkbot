# AWK program bootstrap
# -----------------------------------------------------------------------------
# "THE BEER-WARE LICENSE" (Revision 43) borrowed from FreeBSD's jail.c:
# <tag@cpan.org> wrote this file.  As long as you retain this notice you
# can do whatever you want with this stuff. If we meet some day, and you think
# this stuff is worth it, you can buy me a beer in return.   Scott S. McCoy
# -----------------------------------------------------------------------------
# This module provides a bootstrap for programs that want to declare their
# dependencies using AWKPATH (as per gawk) and the `#use' directive.  This
# program will process the programs provided in the command line and load them
# using the awk executable.

BEGIN {
    loader_pathc = split(ENVIRON["AWKPATH"], loader_pathv, /:/)
}

function loader_readable (file     ,result,x) {
    result = getline x < file
    close(file)

    return result >= 0
}

function loader_find (filename     ,r,i) {
    for (i = 1; i <= loader_pathc; i++) {
        r = loader_pathv[i] "/" filename

        if (loader_readable(r)) {
            return r
        }
    }

    print "error: unable to find file " filename >> "/dev/stderr"
    exit 1
}

## Parse a file and determine all of it's dependencies, and theirs,
# recursively.
#
# filename: The file to inspect.
# loaded: The set of files already loaded (optional)
function loader_deps (filename,loaded   ,input,df,depends) {
    loaded[filename] = 1

    depends = ""

    while ((getline input < filename) > 0) {
        if (input ~ /^#use/) {
            split(input, words, /[\t ][\t ]*/)
            print "loading module " words[2] >> "/dev/stderr"
            df = loader_find(words[2])

            if (loaded[df] != 1) {
                depends = depends " -f " df
                depends = depends loader_deps(df, loaded)
            }
        }
    }

    close(filename)

    return depends
}

function loader_command (program   ,fname,deps,modv,modc,i,awk) {
    awk = ARGV[0]

    fname = loader_find(program)

    if ("" == fname) {
        print "unable to load", program ": file not found" >> "/dev/stderr"
        return
    }


    deps = loader_deps(fname)

    return sprintf("exec %s%s -f %s", \
            awk, deps, fname)
}

function loader_load (program   ,cmd) {
    cmd = loader_command(program)

    for (i = 1; i <= ARGC; i++) {
        cmd = cmd " " ARGV[i]
    }
    
    return system(cmd)
}

##
# Bootstrap.
#
# If awk has been started with -v program=modulename.awk, the loader will start
# with that program.  Otherwise, it can be used as a library.
BEGIN {
    if (program) {
        exit(loader_load(program))
    }
}
