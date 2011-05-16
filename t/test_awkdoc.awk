
#import <awkdoc.awk>
#import <assert.awk>

BEGIN {
    exit 0 # disabled
    assert(length(awkdoc("split")) > 0, "Failed to find snippet for \"split\"")
    assert(length(awkdoc("match")) > 0, "Failed to find snippet for \"match\"")
    assert(length(awkdoc("RS")) > 0, "Failed to find snippet for \"RS\"")
    exit 0
}
