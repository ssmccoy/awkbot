#!/usr/bin/awk -f

BEGIN {
    if (ENVIRON["REQUEST_METHOD"] == "POST") 
        while ( getline ) _cgilib_in = _cgilib_in $0
    if (ENVIRON["REQUEST_METHOD"] == "GET")
        _cgilib_in = ENVIRON["QUERY_STRING"]
}

function params (Query    ,Each,Pairs,i) {
    split(_cgilib_in, Pairs, /\&/)
    i = 0    
    while (Pairs[++i]) {
        split(Pairs[i], Each, /=/)
        Query[Each[1]] = Each[2]
    }
}
