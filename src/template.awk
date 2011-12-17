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
#  - op: ptr
#
# set:
#  - identifier: identifier
#  - value: ptr
#
# val:
#  - value: ptr
#
# when:
#  - expression: ptr
#  - op: ptr
#
# expression:
#  - expression_type: [ "un" | "cmp" ]
#
# un:
#  - value: ptr
#
# cmp:
#  - cmp: comparison
#  - lhs: value ptr
#  - rhs: value ptr
#
# value:
#  - lit: <bool>
#  - token: identifier | literal
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

function node (ir, prev, type   ,node) {
    node = ++ir["node"]

    if (prev) {
        ir[prev, "next"] = node
    }

    ir[node, "type"] = type

    return node
}

function node_loop (ir, array, identifier   ,current) {
    current = ir["node"]

    node = node(ir, current, "loop")

    ir[node, "array"]      = array
    ir[node, "identifier"] = identifier

    return node
}

function node_val (ir, identifier    ,current) {
    current = ir["node"]

    node = node(ir, current, loop)
}
