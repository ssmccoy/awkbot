# -----------------------------------------------------------------------------
# "THE BEER-WARE LICENSE" (Revision 43) borrowed from FreeBSD's jail.c:
# <tag@cpan.org> wrote this file.  As long as you retain this notice you
# can do whatever you want with this stuff. If we meet some day, and you think
# this stuff is worth it, you can buy me a beer in return.   Scott S. McCoy
# -----------------------------------------------------------------------------

#use chr.awk

##
# Data structure design.
#
# N - an item on the stack.
# "ops" - the number of items on the stack
##

BEGIN {
    PUSH  = 1 # Push a value onto the stack
    POP   = 2 # Pop a value from the stack
    PUT   = 3 # Put a value in a location
    COPY  = 4 # Copy a value from one location to another
    CAT   = 5 # Concatenate two values
    PRINT = 6 # Print a value
    JMPIF = 7 # Jump to a point in the stack if a value is > 1
    JMP   = 8 # Jump to a point in the stack
    ADD   = 9 # Add a value to another value
    SUB   = 10 # Subtract a value from another value
    MUL   = 11 # Multiply
    DIV   = 12 # Divide 
    MOD   = 13 # Modulo
}

##
# Stack:
# <n>      - OP REG VAL
# "ops"    - max(n)'
# "ram", k - memory
# "cursor" - cursor (stack pointer)

function vm_init (vm) {
    vm["ops"]    = 0
    vm["cursor"] = 1
}

# Push and pop are special, they can NOT (yes, NOT) be implemented with
# generic symbols, because they change the stack length.
function vm_push (vm, val) {
    vm[++vm["ops"]] = val
}

function vm_pop (vm, sym) {
    vm["ram", sym] = vm[vm["ops"]--]
}

# Put copies a literal
function vm_put (vm, sym, val) {
    vm["ram", sym] = val
}

function vm_copy (vm, sym, val) {
    vm["ram", val] = vm["ram", sym]
}

function vm_cat (vm, sym, val) {
    vm["ram", sym] = vm["ram", sym] vm["ram", val]
}

function vm_add (vm, sym, val) {
    vm["ram", sym] += vm["ram", val]
}

function vm_sub (vm, sym, val) {
    vm["ram", sym] -= vm["ram", val]
}

function vm_mul (vm, sym, val) {
    vm["ram", sym] *= vm["ram", val]
}

function vm_div (vm, sym, val) {
    vm["ram", sym] /= vm["ram", val]
}

function vm_mod (vm, sym, val) {
    vm["ram", sym] %= vm["ram", val]
}

function vm_print (vm, sym) {
    print vm["ram", sym]
}

function vm_jmp (vm, addr) {
    vm["cursor"] = addr
}

function vm_jmpif (vm, sym, addr) {
    if (vm["ram", sym] > 0) {
        vm["cursor"] = addr
    }
}

# Push the stack pointer to the end of the stack so we exit.
# Set the return value.
function vm_exit (vm, val) {
    vm["cursor"] = vm["ops"]
    vm["return"] = val
}

function vm_next (vm    ,c,reg,val,sym,op,arg) {
    val = vm[vm["cursor"]++]

    op  = ord(substr(val, 1, 1))
    sym = substr(val, 2, 4)
    val = substr(val, 6)

    if (op == PUSH) {
        vm_push(vm, val)
    }
    else if (op == POP) {
        vm_pop(vm, sym)
    }
    else if (op == PUT) {
        vm_put(vm, sym, val)
    }
    else if (op == COPY) {
        vm_put(vm, sym, val)
    }
    else if (op == CAT) {
        vm_cat(vm, sym, val)
    }
    else if (op == PRINT) {
        vm_print(vm, sym)
    }
    else if (op == JMPIF) {
        vm_jmpif(vm, sym, val)
    }
    else if (op == JMP) {
        vm_jmp(vm, sym)
    }
    else if (op == ADD) {
        vm_add(vm, sym, val)
    }
    else if (op == SUB) {
        vm_sub(vm, sym, val)
    }
    else if (op == MUL) {
        vm_mul(vm, sym, val)
    }
    else if (op == DIV) {
        vm_div(vm, sym, val)
    }
    else if (op == MOD) {
        vm_mod(vm, sym, val)
    }
    else {
        printf "ERROR: Unknown operation \"%s\"\n", op >> "/dev/stderr"
        exit 1
    }
}

function vm_run (vm) {
    while (vm["ops"] >= vm["cursor"]) {
        vm_next(vm)
    }
}

# Quick test program...
BEGIN {
    vm_init(vm)

    vm_push(vm, chr(PUT) "one 1")
    vm_push(vm, chr(PUT) "cnt 5")
    vm_push(vm, chr(PRINT) "cnt ")
    vm_push(vm, chr(SUB) "cnt one ")
    vm_push(vm, chr(JMPIF) "cnt 3")
    vm_push(vm, chr(PUT) "msg Hello, world!")
    vm_push(vm, chr(PRINT) "msg ")

    vm_run(vm)
}
