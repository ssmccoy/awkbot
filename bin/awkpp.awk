#!/usr/bin/awk -f 
# AWK PP, the awk preprocessor
# ----------------------------------------------------------------------------- 
# "THE BEER-WARE LICENSE" (Revision 43) borrowed from FreeBSD's jail.c: 
# <tag@cpan.org> wrote this file.  As long as you retain this notice you 
# can do whatever you want with this stuff. If we meet some day, and you think 
# this stuff is worth it, you can buy me a beer in return.   Scott S. McCoy 
# -----------------------------------------------------------------------------

#include <ord.awk>
#include <assert.awk>
#include <config.awk>
#include <getopt.awk>
#define STRAPPED 1

BEGIN {
    # We need to do a better job of determining what awk we're running in here
    awk = "awk -f -"

    while ((opt = getopt(ARGC, ARGV, "sc:")) != -1) {
        if (opt == "c") config_file = Optarg
        if (opt == "s") awk = "cat"
    }

    if (config_file) {
        config_load(config_file)

        if (config("awkpp.define") ~ /^[0-9]+/) {
            for (i = 1; i <= config("awkpp.define"); i++) {
                # Define stuff
            }
        }
        else if (config("awkpp.define")) {
            # define one
        }
        if (config("awkpp.load") ~ /^[0-9]+/) {
            # include loop
        }
        else if (config("awkpp.load")) {
            # include one
        }
    }

    # File to processes
    filename = ARGV[--ARGC]

    for (i = 2; i <= ARGC; i++) {
        awk = awk " " ARGV[i]
        delete ARGV[i]
    }

#    while (ARGC > 1) proc_include(ARGV[--ARGC])
    proc_include(filename)

    printf chr(10) | awk
    close(awk)
}

function proc_include (filename     ,stop,il,path,k,location,test,junk) {
    split(ENVIRON["AWKPATH"], path, ":")

    for (k = 1; path[k]; k++) {
        test = path[k] "/" filename
        if ((getline junk <test) >= 0) {
            close(test)
            location = test
            break
        }
    }

    assert(location, "Unable to locate: " filename " in " ENVIRON["AWKPATH"])

    while (getline < location) proc_run(location)
}

function proc_run (location     ,il,junk,macro) {
        if (match($0, /^#define ([[:alnum:]]*)  *([^\\]*)\\? *$/, il)) {
            define[il[1]] = il[2]
            while ($NF == "\\") {
                getline junk < location
                define[il[1]] = define[il[1]] junk
            }
        }
        else if (match($0, /^#if(n?)def ([[:alnum:]]*)$/, il)) {
            if ((il[1] && ! define[il[2]]) || define[il[2]]) {
                while (getline < location) {
                    if (/^#else/) {
                        while (!/^#endif/) getline < location
                        return
                    }
                    if (/^#endif/) return
                    proc_run(location)
                }
            }
            else {
                while (getline < location) {
                    if (/^#else/) {
                        getline < location           # Skip this line
                        while (!/^#endif/) {
                            proc_run(location)       # This strange way of
                            getline < location       # doing things is to make
                        }                            # sure the macros get
                        return                       # stripped
                    }
                }
            }
        }
        else if (match($0, /^#include <([^>]+)>/, il)) {
            if (!included[il[1]]) {
                included[il[1]] = 1
                proc_include(il[1])
            }
        }
        else {
            for (macro in define) gsub(macro, define[macro])
            print | awk
        }
}

