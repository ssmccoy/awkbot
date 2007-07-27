# test queue.awk
#import <queue.awk>

BEGIN {
    push(queue, 1)
    push(queue, 2)
    push(queue, 3) 

    assert((sizeof(queue) == 3), "Sizeof queue" sizeof(queue))
    assert((pop(queue) == 3), "1")
    assert((pop(queue) == 2), "2")


    unshift(queue, 2)
    unshift(queue, 3)

    assert((shift(queue) == 3), "3")
    assert((shift(queue) == 2), "4")
    assert((shift(queue) == 1), "5")
}
