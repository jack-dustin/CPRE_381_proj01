# Isaiah Pridie, Jack Dustin
# CprE 3810 - Assembly Merge Sort
# Start Date: 4.4.2026, 2:08 PM

# a0 used for first element address of chunck
# a1 used for num elements in (current) chunck
# a2 used for last element address of chunck

.data
arr:
    .word 20, 31, 5, 100, 15, 80, 92, 73, 50, 62, 12, 29, 
end_arr:


.text
.global main

main:
lui  a0, 0x10010    # start of data/arr
addi a1, x0, 12     # 12 elements
slli a2, a1, 2      # 12 * 4 gets 48 bytes of data
add  a2, a0, a2     # a2 = Address of last element + 1
addi a2, a2, -4     # a2 = Address of last element


jal  x1, MergeSortRecurse   # Calls MergeSortRecurse. Returns value to register x1 (aka ra)

EXIT:
    wfi

MergeSortRecurse: 
    # if left address >= right address, return/end
    bltu a0, a2, Continue      
        jalr x0, x1, 0  # Canonical ret - Ends Recursive Splitting
    Continue:

    # Save initial values/conditions - recursing will overwrite regsiters
    addi sp, sp, -16    # Reserve Space on stack
    sw   ra, 12(sp)     # Return Value
    sw   a0,  8(sp)     # First element address of chunk
    sw   a1,  4(sp)     # Size of chunk 
    sw   a2,  0(sp)     # Last element address of chunk

    srli a4, a1, 1      # a4 = left size = size / 2     # Compute where to split
    slli a5, a4, 2      # a5 = Number of bytes in left half
    add  a6, a0, a5     # a6 = address of first element in right half
    addi a7, a6, -4     # a7 = address of left element in left half
    sub  t0, a1, a4     # t0 = right size = total size - left size

    # Recurse on left half
    add  a1, a4, x0     # a1 = size = left size
    add  a2, a7, x0     # a2 = last = left last
    jal  ra, MergeSortRecurse   # Calls MergeSortRecurse for left side

    # Hits here after returning from jalr MergeSortRecurse above
    # Restore saved initial values to do right half. We need the original array values. That's why we store and call them back
    lw   a0, 8(sp)      # First element address of chunk
    lw   a1, 4(sp)      # Size of chunk
    lw   a2, 0(sp)      # Last element address of chunk

    # Set right-half arguments
    srli a4, a1, 1      # a4 = left size (recomputed)
    sub  t0, a1, a4     # t0 = right size
    slli a5, a4, 2      # a5 = left size in bytes
    add  a6, a0, a5     # a6 = First address of right side

    add  a0, a6, x0     # a0 = first addrss of right side. Put in register a0
    add  a1, t0, x0     # a1 = right chunk size
    jal  ra, MergeSortRecurse    # Right Side Recusrion

    # Restore the original array a second time. 
    # Need this again because merge needs to store the sorted words into the original array addresses
    lw   ra, 12(sp)     # Return value
    lw   a0,  8(sp)     # First address
    lw   a1,  4(sp)     # Size of array/chunk
    lw   a2,  0(sp)     # Last Address
    addi sp, sp, 16     # Resolve reserved stack space (think of it like freeing malloc - Cleaning up our mess)

    # Recompute split for merge
    srli a4, a1, 1      
    slli a5, a4, 2
    add  a6, a0, a5     # right first
    addi a7, a6, -4     # Left last

    # No branch - fall through to Merge

Merge:
    # Merge recieves a sorted left half and right half. 
      # Merge still needs to compare the elements of the two arrays and grab the lower element. 
      # Store the result in a temporary space in memory
      # After sorting, copy and paste back into original chunk
        # Think of the "original chunk" as the left addresses concatenated with the right side
          # Visual: [ Left Side | Right Side ] --> [1, 2, 3, | 4, 5, 6,]

    # LEFT HALF:
        # First Address = a0    
        # Size = a4
        # Last Address = a7     
    # RIGHT HALF:
        # First Address = a6
        # Size = t0
        # Last Address = a2

    # Logic to actually sort

    jalr x0, 0(ra)  # Canonical format of ret 
