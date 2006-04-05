
function awkdoc(Keyword ,result,line,get,Func,manpage) {
    if (Keyword ~ /^[A-Z]+$/) Func = 0
    else Func = 1

    manpage = "man awk";

    Keyword = "^       " Keyword (match(Keyword,"/") ? "" : 
                                            (Func ? "\\(" : " "))

    while (manpage | getline line ) {
        gsub(/.\010/, "",       line)
        gsub(/[\000-\037]/, "", line)

        if (Func) {
            if (line ~ Keyword) get++
            if (length(line) == 0) get = 0  
        }

        else {
            if (line ~ Keyword) get = 1
            if ((line ~ /^       [A-Z]+/) && (line !~ Keyword)) get = 0
        }

        if (get) result = result line
    }

    close(manpage)

    gsub(/ +/, " ", result)
    gsub(/- /, "",  result)

    return result
}

