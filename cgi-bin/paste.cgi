#!/bin/sh
# awkpp is becoming a maintenance nightmare, and I'm able to ditch it by using
# cpp and it's highly deprecated "import" statement instead.

cd ..

awkpaste=`tempfile`
cpp -I /usr/share/awk/ -I src src/awkpaste.awk 2> /dev/null > $awkpaste

# Now that it's assembled, run it
awk -f $awkpaste

# Clean up our mess
rm $awkpaste
