
## Determine if a file exists *and* is readable.
# filename: The name of the file to test.
# return: a true value if it is readable, a false value otherwise
function exists (filename   ,t) {
    if ((getline t < filename) != -1) {
	close(filename)
	return 1
    }
    else {
	return 0
    }
}
