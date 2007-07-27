# if it's a comment
/^ *#/ {
    
    # The below would look like this, if it wasn't so way too long to fit
    # within a terminal
    # /^ *#
    # *\(\(if\|ifn\|un\)def\|if\|\(el\|end\)if\|define\|include\|import
    # \|else\|error\|pragma\)/b
    # print

    # if it's a preprocessing directive, or atleast looks like one, leave it.
    /^ *# *if/p
    /^ *# *else/p
    /^ *# *ifdef/p
    /^ *# *ifndef/p
    /^ *# *undef/p
    /^ *# *define/p
    /^ *# *include/p
    /^ *# *import/p
    /^ *# *else/p
    /^ *# *elif/p
    /^ *# *endif/p
    /^ *# *error/p
    /^ *# *pragma/p
    /^ *# *line/p
    # Just delete everything else
    d
}
