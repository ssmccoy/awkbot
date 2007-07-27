
function tempfile (prefix   ,call,result) {
    call = "tempfile -p " prefix 
    call | getline result
    close(call) 
    return result
}

