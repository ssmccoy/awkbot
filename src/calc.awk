# by pgas
# Hopefully someone will make this support powers and arbitrary precision
# Also it should work without spaces.
# simple 4 ops calculator
# usage:    print calc("5 * (1 + 2) * 5 + 7")

# reads and update s[0]
# return the first token
function next_token(s, t) {
    sub(/^[[:space:]]*/,"", s[0])
    if (match(s[0], /^[()]/) || 
	match(s[0], /^[-+]?[0-9]+(\.[0-9]+)*/) ||
	match(s[0], /^[-+*\/]/)) {
	t = substr(s[0], RSTART, RLENGTH)
	s[0] = substr(s[0], RLENGTH+1)
	return t
    } else {
	return ""
    }
}

# read input and performs the shuting-yard algorithm
# result is in postfixed
# return the length of the postfixed array
function s_y( input, postfixed       ,len, stack, head, op, s, token, pre) {
    # precedence table
    pre["+"]=pre["-"]=1
    pre["*"]=pre["/"]=2
    pre["("]=0
    s[0] = input
    while (token = next_token(s)) {
	if (token ~ /^[-+]?[0-9]+(\.[0-9]+)*/) {
	    postfixed[++len] = token
	} else if (token ~ /[-+\/*]/) {
	    while ((head > 0) && (pre[token] <= pre[stack[head]])) {
		postfixed[++len] = stack[head]
		head-=1
	    }
	    stack[++head] = token
	} else if (token ~ /[(]/) {
	    stack[++head] = token
	} else if (token ~ /[)]/) {
	    while ((head > 0) && (stack[head] != "(")) {
		postfixed[++len] = stack[head]
		head -= 1
	    }
	    if (head == 0) { 
		print "Syntax Error"
		return 0
	    } else {
		head -= 1
	    }
	}
    }
    while ((head > 0)) { postfixed[++len] = stack[head--] }
    return len
}

#eval the postfixed operation
function eval(postfixed, len, stack, ptr, i) {
    for (i=1; i<=len; i++) {
	if (postfixed[i] == "-") {
	    ptr-=1
	    stack[ptr] = stack[ptr] - stack[ptr+1]
	} else if (postfixed[i] == "+") {
	    ptr-=1
	    stack[ptr] = stack[ptr] + stack[ptr+1]
	} else if (postfixed[i] == "*") {
	    ptr-=1
	    stack[ptr] = stack[ptr] * stack[ptr+1]
	} else if (postfixed[i] == "/") {
	    ptr-=1
	    stack[ptr] = stack[ptr] / stack[ptr+1]
	} else {
	    stack[++ptr] = postfixed[i]
	}
    }
    return stack[ptr]
} 

function calc(input,       postfixed, len) {
    len = s_y(input, postfixed)
    return eval(postfixed,len)
}
