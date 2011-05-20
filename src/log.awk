# Shorthand for sending messages to the logger module.
# -----------------------------------------------------------------------------
# "THE BEER-WARE LICENSE" (Revision 43) borrowed from FreeBSD's jail.c:
# <tag@cpan.org> wrote this file.  As long as you retain this notice you
# can do whatever you want with this stuff. If we meet some day, and you think
# this stuff is worth it, you can buy me a beer in return.   Scott S. McCoy
# -----------------------------------------------------------------------------
# Use this within modules to log using a concise syntax.
# It assumes the logger module is instantiated with the name "log"

## Log an error level message.
# error("an %s", "example")
#
# message: The (optionally formatted) message to write to the log
# a1... use the syntax of printf()
function error (message, a1,a2,a3,a4,a5,a6,a7) {
    kernel_send("log", "error", this, message, a1,a2,a3,a4,a5,a6,a7)
}

## Log an error warn message.
# see error()
function warn (message, a1,a2,a3,a4,a5,a6,a7) {
    kernel_send("log", "warn", this, message, a1,a2,a3,a4,a5,a6,a7)
}

## Log an error info message.
# see error()
function info (message, a1,a2,a3,a4,a5,a6,a7) {
    kernel_send("log", "info", this, message, a1,a2,a3,a4,a5,a6,a7)
}

## Log an error debug message.
# see error()
function debug (message, a1,a2,a3,a4,a5,a6,a7) {
    kernel_send("log", "debug", this, message, a1,a2,a3,a4,a5,a6,a7)
}
