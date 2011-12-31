# A template compiler that targets the vm.awk bytecode.
# -----------------------------------------------------------------------------
# "THE BEER-WARE LICENSE" (Revision 43) borrowed from FreeBSD's jail.c:
# <tag@cpan.org> wrote this file.  As long as you retain this notice you
# can do whatever you want with this stuff. If we meet some day, and you think
# this stuff is worth it, you can buy me a beer in return.   Scott S. McCoy
# -----------------------------------------------------------------------------

#use bitwise.awk

# Template language (in some form of EBNF)
# body       = string | "{" space statement space "}" | body
# statement  = get | loop | set | when | end
# identifier = string
# loop       = "loop" space identifier space ":"   space identifier
# set        = "set"  space identifier space value
# when       = "when" space expression
# get        = "val"  space value
# end        = "end"
# expression = value space comparison space value | value
# comparison = "==" | "!=" | ">" | "<"
# value      = identifier | "\"" string "\"" | digits

# Example:
# {when foo}
#   There is a foo
#   {loop bar: item}
#     Here's an item: {val item}
#   {end}
# {end}

# Intermediate Representation
# To create a tree, simulate pointers with index references.
#
# node, next = *ptr
# node, type = keyword
#
# node attributes:
# loop:
#  - array: identifier
#  - identifier: identifier
#  - branch: ptr
#
# set:
#  - identifier: identifier
#  - value: ptr
#
# value:
#  - token: identifier
#
# when:
#  - expression: ptr
#  - when: ptr
#  - otherwise: ptr
#
# expression:
#  - expression_type: [ cmp | value | literal ]
#
# cmp:
#  - cmp: comparison
#  - lhs: [ value | literal ]
#  - rhs: [ value | literal ]
#
# literal:
#  - token: string
#
# Bytecode generation will require recursion.
#
# (node     ,next) {
#   <action...>
#
#   if (next = ir[node, "next"]) {
#       (next)
#   }
# }

function node_create (ir, type   ,node) {
    node = ++ir["node"]

    ir[node, "type"] = type

    return node
}

function node_next (ir, node, ptr) {
    ir[node, "next"] = ptr
}

function node_loop (ir, array, identifier, ptr   ,node) {
    node = node_create(ir, "loop")

    ir[node, "array"]      = array
    ir[node, "identifier"] = identifier
    ir[node, "op"]         = ptr

    return node
}

function node_when (ir, expression, when, otherwise) {
    node = node_create(ir, "when")

    ir[node, "expression"] = expression
    ir[node, "when"]       = when
    ir[node, "otherwise"]  = otherwise

    return node
}

function node_otherwise (ir, ptr) {
    node = node_create(ir, "otherwise")

    ir[node, "op"] = ptr

    return node
}

function node_cmp (ir, cmp, lhs, rhs) {
    node = node_create(ir, "cmp")

    ir[node, "cmp"] = cmp
    ir[node, "lhs"] = lhs
    ir[node, "rhs"] = rhs

    return node
}

function node_value (ir, token ,node) {
    node = node_create(ir, "value")
    
    ir[node, "token"] = token

    return node
}

function node_literal (ir, token    ,node) {
    node = node_create(ir, "literal")

    ir[node, "token"] = token

    return node
}

function parse_error (format, a1, a2, a3) {
    # TODO: Line numbers...this can be done by identifying the number of
    # newlines between the original string and the current "string" which has
    # been chomped up until this point, but it might not always be the most
    # accurate.  Otherwise, we can identify line numbers only by keeping track
    # of them in parse_node() and passing the line number into each parsing
    # function for placement in the IR.
    printf format "\n", a1, a2, a3 > "/dev/stderr"
}

function parse_value (ir, string) {
    # Trim "val" off, but only when it's present and followed by some kind of
    # blank space.  This way identifiers can contain the substring "val" and
    # not break.  But they cannot be named "val"
    if (match(string, /val[ \t][ \t]*/)) {
        string = substr(string, RSTART + RLENGTH)
    }

    # Literal string
    if (string ~ /^".*"$/) {
        string = substr(string, 2, length(string) - 2)

        # Unescape all supported escapes
        gsub(/\\"/, "\"", string)
        gsub(/\\n/, "\n", string)

        return node_literal(ir, string)
    }
    # Literal numeric
    if (string ~ /^[0-9._-][0-9._]/) {
        return node_literal(ir, string)
    }
    # Variable
    if (string ~ /^[^[:blank:]][^[:blank:]]*$/) {
        return node_value(ir, string)
    }

    parse_error("Expected identifier or literal, found: %s", string)
}

function parse_expression (ir, string   ,lhs,cmp,rhs,l) {
    l = split(string, parts)

    if (l == 1) {
        return parse_value(ir, string)
    }
    else if (l == 3) {
        lhs = parse_value(ir, parts[1])
        cmp = parts[2]
        rhs = parse_value(ir, parts[3])
        return node_cmp(ir, cmp, lhs, rhs)
    }
    else {
        parse_error("Unable to parse expression: %s", string)
    }
}

function parse_when (ir, string     ,expression,block,when,otherwise,node) {
    string = substr(string, index(string, "when") + 4)

    expression = parse_expression(ir, string)
    when       = parse_block(ir)

    if (ir["why"] == "otherwise") {
        # Back to problems.  I need to return when and not set
        # node_next()...unless
        otherwise = parse_block(ir)
    }
    # If the block terminated on an otherwise...
    else if (ir["why"] != "end") {
        parse_error("Reached EOF while parsing body of: %s", string)
    }

    node = node_when(ir, expression, when, otherwise)

    return node
}

function parse_loop (ir, string,c,array,identifier) {
    string = substr(string, index(string, "loop") + 4)

    # Strip whitespace
    gsub(/[ \t][ \t]*/, "", string)

    c          = index(string, ":")
    array      = substr(string, 1, c - 1)
    identifier = substr(string, c + 1)

    return node_loop(ir, array, identifier, parse_block(ir))
}

function parse_node (ir     ,keyword,string,command,parts,token,start,len) {
#   print "parsing node";
    string = ir["string"]

    if (match(string, /{[^}][^}\n]*}/)) {
#       print "found command";
        start = RSTART
        len   = RLENGTH

        if (start > 1) {
            token = substr(string, 1, start - 1)

            ir["string"] = string = substr(string, start)

            # If the token before the matched command is not entirely
            # whitespace, create a literal node for it.  Otherwise just move
            # along having it been trimmed above.
            if (token !~ /^[[:blank:]][[:blank:]]*$/) {
                node = node_literal(ir, token)

                return node
            }
            else {
                print "skiiiip it"
            }
        }


        # If we don't have a huge chunk of  non-whitespace characters, then
        # we've hit a command.  Parse the command...
        command = substr(string, start + 1, len - 2)
        split(command, parts)

        # Record why we dispatched what we dispatched, this is used for
        # determining what caused the end of a block (e.g., was it "end",
        # "otherwise"?)
        ir["why"] = keyword = parts[1]

        # Trim the command off before we enter the parsing functions...
        ir["string"] = substr(string, start + len)

        # End just returns, a missing node is treated as a signal by the
        # recursive descent parser.  Excessive block closures are identified,
        # runaway blocks are not.  This could be fixed but it would add
        # complexity.
        if (keyword == "end")       return
        if (keyword == "otherwise") return 
        if (keyword == "when")      return parse_when(ir,  command)
        if (keyword == "loop")      return parse_loop(ir,  command)
        if (keyword == "val")       return parse_value(ir, command)

        ir["string"] = substr(string, len)
    }
    else if (length(string) > 0) {
        # Slurp the whole thing, it's all just a literal.
        delete ir["string"]
        return node_literal(ir, string)
    }
}

##
# Parse a whole block into the op tree.
function parse_block (ir    ,cursor,first,node) {
    # end nodes come back as blanks, since they are discarded anyway.
    while (node = parse_node(ir)) {
        if (!first) {
            cursor = first = node
        }


        # Scroll forward incase parse_node returned multiple nodes (this
        # happens with when/otherwise)
        while (ir[cursor, "next"] > 0) {
            cursor = ir[cursor, "next"]
        }

        if (node != cursor) {
            node_next(ir, cursor, node)
        }

        cursor = node
    }

    return first
}

##
# Parse a string into an op tree, this is effectively an alias for parse_block
# which knows where to put the string.
function parse (ir, string  ,program) {
    ir["string"] = string

    # The outer level of a full template is a block
    program = parse_block(ir)

    return program
}

function compile (ir, ops) {
    # The following arrays are for processing:
    # tags:
    #   The tags appear in sequential order.  They represent the locations of
    #   addresses which must be replaced.
    # targets:
    #   Each tag has a corresponding target.  The target marks the address that
    #   the tag must jump to.  It's added (as the current op) once the end of a
    #   given block is reached.
    # ids:
    #   The ids represent addresses in RAM.  They are a sequential array of
    #   identifier names, the key being their address.  The identifier names
    #   are written to a table in slot "0", unseparated.
    # Compile the ir into byte code...

    # This will take two passes, first, we need to build an op tree with empty
    # jump addresses, and queue up addresses as we discover them.  Then we need
    # to filter the op tree to insert the addresses.  The end result will be a
    # working bytecode for vm.awk.
}

BEGIN {
    # NUL RS.
    RS = "\0"

    getline template < "test.tmpl"

    #print "complete template:\n", template

    parse(ir, template)

    for (key in ir) {
        split(key, pair, SUBSEP)
        gsub(/\n/, "\\n", ir[key])
        print(pair[1], pair[2] ":", ir[key])
    }
}
