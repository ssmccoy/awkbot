# A simple template system in awk.
# -----------------------------------------------------------------------------
# "THE BEER-WARE LICENSE" (Revision 43) borrowed from FreeBSD's jail.c:
# <tag@cpan.org> wrote this file.  As long as you retain this notice you
# can do whatever you want with this stuff. If we meet some day, and you think
# this stuff is worth it, you can buy me a beer in return.   Scott S. McCoy
# -----------------------------------------------------------------------------

BEGIN {
    TSTRING = 1
    TVAL    = 2
    TENUM   = 3
}

##
# Data structure design.
#
# "opc"             : number of ops
# "ops",    i       : TSTRING | TVAL | TENUM (opcode)
# "tokens", i       : name | string (value of op token)
# "tokenl", i       : The size of the opcode slice of i is an enumeration.
# "values", name    : Variable value.
# "values", name, i : Array element value
# "values", name    : Element name (for TENUM/array types *only*)
# "valuec", name    : Array length
##

##
# Template syntax:
#
# {varname}            - A variable
# {arrayname: element} - The beginning of an enumeration segment
# {arrayname}          - The end of an enumeration segment
##

# To simplify, everything should just be a loop.
function template_op_add (template, op, token   ,opi) {
    opi = ++template["opc"]

    template["ops"   , opi] = op
    template["tokens", opi] = token
}

function template_loop_open (template, scope, name,  ld) {
    template_op_add(template, enum, name)

    ld = ++scope["ld"]

    scope[ld, "start"] = template["opc"]
    scope[ld, "end"]   = template["opc"]
}

function template_loop_is_open (scope) {
    return scope["ld"] > 0
}

function template_loop_close (template, scope   ,start,end,ld) {
    ld    = scope["ld"]
    start = scope[ld, "start"]
    end   = scope[ld, "end"]

    template["tokenl", start] = end - start
}

function template_loop_op_add (template, scope, op, token   ,ld) {
    template_op_add(template, op, token)

    ld = scope["ld"]

    # Push the end of this scope out.
    scope[ld, "end"] = template["opc"]
}

function template_loop_is_closure (template, scope, token   ,ld,start) {
    ld    = scope["ld"]
    start = scope[ld, "start"]

    return template["tokens", start] == token
}

function template_init (template, filename, input, tokens, c,i,ld,str,scope) {
    # Set the current loop depth to zero...
    ld = 0

    # The parser will be fun...
    while ((getline input < filename) >= 0) {
        while (match(input, /{[^a-zA-Z][^a-zA-Z_.]*(: [a-zA-Z][a-zA-Z_.]*)*}/)) {
            # Append the string leading to the operation
            if (RSTART > 1) {
                str = substr(input, 1, RSTART - 1)
                template_op_add(template, TSTRING, str)
            }

            # Trim the {}'s off the token.
            str = substr(input, RSTART + 1, RLENGTH - 2)

            # If this token is an enumeration, it'll have an :
            if (i = index(str, ":")) {
                # Increase the loop depth
                ld++

                # Open the loop (this adds the op)
                template_loop_open(template, scope, substr(str, 1, i - 1))

                # Get the element name...
                str = substr(str, i + 2)

                # For the array array name, set the element name..
                template_set(template, scope[ld], str)
            }
            # Otherwise it's a variable or loop closure
            else {
                # We're inside a loop
                if (template_loop_is_open(scope)) {
                    # If the name is a match, then it's a closure
                    if (template_loop_is_closing(scope, str)) {
            # Inside a loop
            else if (template_loop_is_open(scope)) {
                if (template_loop_is_closure(template, scope, str)) {
                    template_loop_close(template, scope)
                }

                template_loop_op_add(token, scope, TVAL, );
            }
        }
    }
}

function template_render (template  ,i,opc,op,result,ec,e,n,var,label) {
    result = ""

    if (opc == "") {
        opc = template["opc"]
    }
    if (i == "") {
        i = 1
    }

    for (; i <= opc; i++) {
        op = template["ops", i]

        # TODO 2011-10-18T12:20:17Z-0700
        # Add type checking...we should error if we try to enumerate over a
        # string value.
        if (op == TSTRING) {
            result = template["tokens", i]
        }
        else if (op == TVAL) {
            result = template["values", template["tokens", i]]
        }
        else if (op == TENUM) {
            var = template["tokens", i]
            ec  = template["valuec", var]
            n   = template["tokenl", i]

            # For the given number of element (the number of values stored
            # here), run the size of the template block that creates this loop
            # through template_render recursively to create iterations.
            i++

            for (e = 1; e <= ec; e++) {
                # This makes the value name for TVAL global for this particular
                # iteration, adjusting it each time so that TVAL resolves
                # properly to the given element.
                template_set(template, var, template["values", var, e])

                template_render(template, i, n)
            }

            # When we're done forward the opcode index by the number of
            # operations which created this block.
            i += n
        }
    }
}

##
# Add an array to the template.
#
# template: The template data-structure.
# name: The name of the array in the template.
# elements: The array itself.
# elementc: The number of elements.
function template_add (template, name, elements, elementc     ,i) {
    template["valuec", name] = elementc

    for (i = 1; i <= elementc; i++) {
        template["values", name, i]
    }
}

##
# Set a variable in a template.
#
# template: The template data-structure
# name: The name of the varaible.
# value: The value of the variable.
function template_set (template, name, value) {
    template["values", name] = value
}
