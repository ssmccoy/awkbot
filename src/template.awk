# A template compiler that targets the vm.awk bytecode.
# -----------------------------------------------------------------------------
# "THE BEER-WARE LICENSE" (Revision 43) borrowed from FreeBSD's jail.c:
# <tag@cpan.org> wrote this file.  As long as you retain this notice you
# can do whatever you want with this stuff. If we meet some day, and you think
# this stuff is worth it, you can buy me a beer in return.   Scott S. McCoy
# -----------------------------------------------------------------------------

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
# val:
#  - token: identifier
#
# when:
#  - expression: ptr
#  - op: ptr
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

function node (ir, type   ,node) {
    node = ++ir["node"]

    ir[node, "type"] = type

    return node
}

function node_next (ir, node, ptr) {
    ir[node, "next"] = ptr
}

function node_loop (ir, array, identifier, ptr   ,node) {
    node = node(ir, "loop")

    ir[node, "array"]      = array
    ir[node, "identifier"] = identifier
    ir[node, "op"]         = ptr

    return node
}

function node_value (ir, token ,node) {
    node = node(ir, "value")
    
    ir[node, "token"] = token

    return node
}

function node_literal (ir, token    ,node) {
    node = node(ir, "literal")

    ir[node, "token"] = token
}

function node_val (ir, identifier    ,node) {
    node = node(ir, "val")

    ir[node, "value"]
}

# There are going to be fairly big problems with this parsing engine.
block = parse_block()
node = node_loop(ir, array, identifier, block)
node_next(ir, node, cont_parsing...?)
