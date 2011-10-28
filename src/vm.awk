# -----------------------------------------------------------------------------
# "THE BEER-WARE LICENSE" (Revision 43) borrowed from FreeBSD's jail.c:
# <tag@cpan.org> wrote this file.  As long as you retain this notice you
# can do whatever you want with this stuff. If we meet some day, and you think
# this stuff is worth it, you can buy me a beer in return.   Scott S. McCoy
# -----------------------------------------------------------------------------


# TODO This should be a library...(comes from chr.awk)
BEGIN {
    for (d = 0; d <= 255; d++) {
        c = sprintf("%c", d)
        x = sprintf("%02X", d)
        _dec_to_hex[d] = x
        _chr_to_dec[c] = d
        _hex_to_dec[x] = d
        _dec_to_chr[d] = c
    }
}


# Oridinal value for the supplied character
function ord (c) {
    return _chr_to_dec[c]
}

# Character value for the supplied decimal (ordinal)
function chr (d) {
    return _dec_to_chr[d]
}

# Decimal value for the supplied hex string (ordinal)
function dec (x) {
    return _hex_to_dec[toupper(x)]
}

# Hex value for the supplied decimal
function hex (d) {
    return _dec_to_hex[d]
}

# END TODO

##
# Data structure design.
#
# N - an item on the stack.
# "ops" - the number of items on the stack
##

BEGIN {
    PUSH    = 01 # Push a value onto the stack
    POP     = 02 # Pop a value off the stack
    READ    = 03 # Read a value from a location
    COPY    = 04 # Copy a value into a location
    JMP     = 05 # Jump to a given position in the stack
    JMPIF   = 06 # Jump to a given position in the stack of the register > 0
    ADD     = 07 # Add a value to the register
    SUB     = 08 # Substract a value from the register
    PRINT   = 09 # Print to standard output
    LIT     = 10 # Copy the given input into the register
    CAT     = 11 # Concatenate a value on the register
}

##
# Stack:
# <n>      - OP SUBSEP VAL
# "ops"    - max(n)'
# "reg"    - The register
# "ram", k - memory
# "cursor" - cursor (stack pointer)

function vm_push (vm, value) {
    vm[++vm["ops"]] = value
}

function vm_pop (vm, arg) {
    vm["ram", arg] = vm[vm["ops"]--]
}

function vm_read (vm, val) {
    vm["register"] = val
}

function vm_copy (vm, arg) {
    vm["ram", arg] = vm["register"]
}

function vm_jmp (vm, val) {
    vm["cursor"] = val
}

function vm_jmpif (vm, val) {
    if (vm["register"] > 0) {
        vm["cursor"] = val
    }
}

function vm_add (vm, val) {
    vm["register"] += val
}

function vm_sub (vm, val) {
    vm["register"] -= val
}

function vm_print (vm, val) {
    print val
}

function vm_lit (vm, arg) {
    vm["register"] = arg
}

function vm_cat (vm, val) {
    vm["register"] = vm["register"] val
}

function vm_next (vm    ,c,val,op,arg) {
    c   = vm["cursor"]
    val = vm[++c]

    op  = ord(substr(val, 1, 1))
    arg = substr(val, 2)

    val = vm["ram", arg]

    vm["cursor"] = c

    if (op == PUSH) {
        vm_push(vm, val)
    }
    else if (op == POP) {
        vm_pop(vm, arg)
    }
    else if (op == READ) {
        vm_read(vm, val)
    }
    else if (op == COPY) {
        vm_copy(vm, arg)
    }
    else if (op == JMP) {
        vm_jmp(vm, val)
    }
    else if (op == JMPIF) {
        vm_jmpif(vm, val)
    }
    else if (op == ADD) {
        vm_add(vm, val)
    }
    else if (op == SUB) {
        vm_sub(vm, val)
    }
    else if (op == PRINT) {
        vm_print(vm, val)
    }
    else if (op == LIT) {
        vm_lit(vm, arg)
    }
    else if (op == CAT) {
        vm_cat(vm, val)
    }
    else {
        printf "ERROR: Unknown operation \"%s\"\n", op >> "/dev/stderr"
        exit 1
    }
}

function vm_run (vm) {
    while (vm["ops"] > vm["cursor"]) {
        vm_next(vm)
    }
}

# Quick test program...
BEGIN {
    vm_push(vm, chr(LIT) "Hello,")
    vm_push(vm, chr(COPY) "m1")
    vm_push(vm, chr(LIT) " world!")
    vm_push(vm, chr(COPY) "m2")
    vm_push(vm, chr(READ) "m1")
    vm_push(vm, chr(CAT) "m2")
    vm_push(vm, chr(COPY) "message")
    vm_push(vm, chr(PRINT) "message")

    vm_run(vm)
}
