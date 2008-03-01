#!/bin/sh
# awkpp is becoming a maintenance nightmare, and I'm able to ditch it by using
# cpp and it's highly deprecated "import" statement instead.

cd ..

awkpaste=`tempfile`
cpp -I /usr/share/awk/ -I src src/awkpaste.awk 2> /dev/null > $awkpaste

# Give our continuous input through a pipe to tail.  tail -f never exits.
# Note, that this means awkbot never exits unless killed from the outside.
awk -f $awkpaste

# Clean up our mess
#rm $awkpaste
