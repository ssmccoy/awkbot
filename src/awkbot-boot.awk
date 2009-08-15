#!/usr/bin/awk
# ----------------------------------------------------------------------------- 
# "THE BEER-WARE LICENSE" (Revision 43) borrowed from FreeBSD's jail.c: 
# <tag@cpan.org> wrote this file.  As long as you retain this notice you 
# can do whatever you want with this stuff. If we meet some day, and you think 
# this stuff is worth it, you can buy me a beer in return.   Scott S. McCoy 
# -----------------------------------------------------------------------------

# Allocate tempfile for awkbot.
#
# This is used so awkbot's tempfile can be allocated and stored where it can be
# fetched prior to further execution...

#import <tempfile.awk>
#import <config.awk>
#import <awkbot_db_mysql.awk>

BEGIN {
    tempfilename = tempfile("awkbot")
    config_load("etc/awkbot.conf")
    awkbot_db_init()
    awkbot_db_status_livefeed(tempfilename)
    print tempfilename
}
