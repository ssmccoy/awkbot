# -----------------------------------------------------------------------------
# "THE BEER-WARE LICENSE" (Revision 43) borrowed from FreeBSD's jail.c:
# <tag@cpan.org> wrote this file.  As long as you retain this notice you
# can do whatever you want with this stuff. If we meet some day, and you think
# this stuff is worth it, you can buy me a beer in return.   Scott S. McCoy
# -----------------------------------------------------------------------------

# Simple markov implementation designed for IRC logs...
BEGIN {
    MARKOV_MAXWORDS = 25
    NONWORD         = "\n"
}

function markov_calculate (filename ,start,a,b,p,i,l,r,states,nsuffix,result) 
{
    result = ""

    a = b = NONWORD

    while ((getline entry < filename) > 0) {
        if (entry ~ /[^ ][^ ]* PRIVMSG /) {
            split(entry, p, ":")
    
            line = p[3]
            l = split(line,  p, " ")
    
            for (i = 1; i < l; i++) {
                states[a, b, ++nsuffix[a, b]] = p[i]
    
                a = b
                b = p[i]
            }
        }
    }

    close(filename)

    states[a, b, ++nsuffix[a, b]] = NONWORD

    a = b = NONWORD
    
    for (i = 0; i < MARKOV_MAXWORDS; i++) {
        l = int(rand() * nsuffix[a, b]) + 1
        r = states[a, b, l]

        if (r == NONWORD)
            return result

        result = result " " r

        a = b
        b = r
    }

    return result
}

BEGIN {
    print markov_calculate(ARGV[1]);
}
