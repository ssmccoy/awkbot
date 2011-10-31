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
		   # operations are split into 3 groups
    REGISTER = 000 #  0   - 84 are "register source" (value comes from register)
    SYMBOL   = 085 #  85  - 169 are "symbol source" (value IS symbol)
    MEMORY   = 170 #  170 - 255 are "memory source" (value OF symbol)

		   # This reduces the number of conditional branches by letting
		   # LIT and READ be implemented by the same operation, among
		   # other optimizations

    # "N" symbols are NOOPs on the register, but not on symbols or memory.
    COPY     = 3 # Put the given segment into the register (NOOP)
    NCOPY    = 4 # Put the register value somewhere (NOOP)
    PRINT    = 5 # Print the register value
    JMP	     = 6 # Jump to the address in the register (nonzero)
    DUB	     = 7 # Double the value of the register (add register to itself)
    ZERO     = 8 # Subtract the register value from itself (creating zero)
    RCAT     = 9 # Concatenate the register value onto the given symbol
    RPUSH    = 10 # Push the register value onto the stack.
    RPOP     = 11 # Remove the value from the stack, placing it in the register.

    SUB	     = MEMORY + ZERO  # Subtract the value from the register value
    ADD	     = MEMORY + DUB   # Add the value of the memory
    JMPIF    = MEMORY + JMP   # Jump if the given value > zero
    READ     = MEMORY + COPY  # Put the symbol value into the register.
    PUSH     = MEMORY + PUSH  # Push the symbol value on the stack
    CAT	     = MEMORY + RCAT  # Concatenate the given value onto the register

    # "D" symbols are dynamic operations
    DCOPY    = MEMORY + NCOPY # Careful, this puts the register value in a
			      # dynamic location 
    DPRINT   = MEMORY + PRINT

    LSUB     = SYMBOL + ZERO  # Subtract the symbol from the register
    LADD     = SYMBOL + DUB   # Add the symbol to the register
#   COPY     = SYMBOL + NCOPY # Put the register value into the given location
    LJMPIF   = SYMBOL + JMP
    LIT      = SYMBOL + COPY  # Put the literal symbol into the register.
    LPUSH    = SYMBOL + PUSH  # Put the symbol onto the stack.
    POP	     = SYMBOL + POP   # Remove the value copying it to the given
                              # location
    LCAT     = SYMBOL + RCAT
    LPRINT   = SYMBOL + PRINT
}

##
# Stack:
# <n>      - OP SUBSEP VAL
# "ops"    - max(n)'
# "reg"    - The register
# "ram", k - memory
# "cursor" - cursor (stack pointer)

# Push and pop are special, they can NOT (yes, NOT) be implemented with
# generic symbols, because they change the stack length.
function vm_push (vm, val) {
    vm[++vm["ops"]] = val
    print "push: " ord(substr(val, 1, 1))
}

function vm_pop (vm, sym) {
    vm["ram", arg] = vm[vm["ops"]--]
}

# Put a value into a symbol
function vm_put (vm, sym, val) {
    printf "%s: %s\n", sym, val
    vm[sym] = val
}

function vm_add (vm, sym, val) {
    vm[sym] += val
}

function vm_sub (vm, sym, val) {
    vm[sym] -= val
}

function vm_div (vm, sym, val) {
    vm[sym] /= val
}

function vm_mul (vm, sym, val) {
    vm[sym] *= val
}

function vm_cat (vm, sym, val) {
    printf "cat: %s %s\n", sym, vm[sym] val
    vm[sym] = vm[sym] val
}

function vm_print (vm, val) {
    print val
}

# This one is dicey, we move the cursor to the given value.
function vm_jmp (vm, sym, val) {
    if (vm[sym] > 0) {
        printf "jmp: %04d\n", val
	vm["cursor"] = val
    }
}

# Push the stack pointer to the end of the stack so we exit.
# Set the return value.
function vm_exit (vm, val) {
    vm["cursor"] = vm["ops"]
    vm["return"] = val
}

function vm_next (vm    ,c,reg,val,sym,op,arg) {
    val = vm[++vm["cursor"]]

    op  = ord(substr(val, 1, 1))
    arg = substr(val, 2)

    printf "%04d: %02d, %s\n", vm["cursor"], op, arg

    val = vm["ram", arg]

    reg = vm["register"]
    sym = arg

    if (op > MEMORY) {
	val = vm["ram", sym]
	op -= MEMORY
	sym = "register"
    }
    else if (op > SYMBOL) {
	val = sym
	op -= SYMBOL
	sym = "register"
    }
    else {
	val = reg
	# op -= 0
        # If the operations don't 
        sym = "ram" SUBSEP sym
    }

    if (op == RPUSH) {
        vm_push(vm, val)
    }
    else if (op == RPOP) {
        vm_pop(vm, val)
    }
    else if (op == COPY) {
        vm_put(vm, sym, val)
    }
    else if (op == NCOPY) {
        vm_put(vm, sym, reg)
    }
    else if (op == PRINT) {
        vm_print(vm, val)
    }
    else if (op == JMP) {
        vm_jmp(vm, sym, val)
    }
    # These symbols are confusing because they're based on register, register
    # operations.  It might have made more sense to start with MEMORY
    # operations...
    else if (op == DUB) {
        vm_add(vm, sym, val)
    }
    else if (op == ZERO) {
        vm_sub(vm, sym, val)
    }
    else if (op == RCAT) {
        vm_cat(vm, sym, val)
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

    vm_push(vm, chr(LIT) 1)
    vm_push(vm, chr(LJMPIF) (vm["ops"] + 1))
    vm_push(vm, chr(LPRINT) "One")
    vm_push(vm, chr(LPRINT) "Two")

    vm_run(vm)
}
