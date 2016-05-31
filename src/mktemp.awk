
#use qx.awk

function mktemp (   tempfile,c) {
    return qx("mktemp")
}

