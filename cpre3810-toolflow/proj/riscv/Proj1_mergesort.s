# Isaiah Pridie, Jack Dustin
# CprE 3810 - Assembly Merge Sort
# Start Date: 4.4.2026, 2:08 PM

# sort(a0=array base, a1=size)
# MergeSortRecurse uses:
#   a0 = first element address of chunk
#   a1 = num elements in chunk
#   a2 = last element address of chunk

.data
array_size:
    .word 12

array:
    .word 20, 31, 5, 100, 15, 80, 92, 73, 50, 62, 12, 29

temp:
    .space 2048          # 512 words * 4 bytes

.text
.globl main
.globl sort

main:
    # Save return address
    addi sp, sp, -16
    sw   ra, 12(sp)

    # Call sort(array, array_size)
    lui  a0, %hi(array)
    addi a0, a0, %lo(array)

    lui  t0, %hi(array_size)
    addi t0, t0, %lo(array_size)
    lw   a1, 0(t0)

    jal  ra, sort

    # Restore return address
    lw   ra, 12(sp)
    addi sp, sp, 16

EXIT:
    wfi


# void sort(int* array, int size)
sort:
    # Base case: size <= 1
    addi t0, x0, 1
    bgeu t0, a1, SortReturn

    # Save caller return address
    addi sp, sp, -16
    sw   ra, 12(sp)

    # Compute last address of chunk into a2
    slli a2, a1, 2
    add  a2, a0, a2
    addi a2, a2, -4

    jal  ra, MergeSortRecurse

    # Restore caller return address
    lw   ra, 12(sp)
    addi sp, sp, 16

SortReturn:
    jalr x0, 0(ra)


MergeSortRecurse:
    # Base case: size <= 1
    addi t1, x0, 1
    bgeu t1, a1, MergeDoneReturn

    # 32-byte stack frame, 16-byte aligned
    addi sp, sp, -32
    sw   ra, 28(sp)
    sw   a0, 24(sp)
    sw   a1, 20(sp)
    sw   a2, 16(sp)

    # Compute split
    srli a4, a1, 1         # a4 = left size
    slli a5, a4, 2         # a5 = left half bytes
    add  a6, a0, a5        # a6 = first address of right half
    addi a7, a6, -4        # a7 = last address of left half
    sub  t0, a1, a4        # t0 = right size

    sw   t0, 12(sp)        # save right size

    # Recurse on left half
    add  a1, a4, x0
    add  a2, a7, x0
    jal  ra, MergeSortRecurse

    # Restore original chunk values
    lw   a0, 24(sp)
    lw   a1, 20(sp)
    lw   a2, 16(sp)

    # Recompute right-half bounds
    srli a4, a1, 1
    sub  t0, a1, a4
    slli a5, a4, 2
    add  a6, a0, a5

    # Recurse on right half
    add  a0, a6, x0
    add  a1, t0, x0
    jal  ra, MergeSortRecurse

    # Restore everything for merge
    lw   ra, 28(sp)
    lw   a0, 24(sp)
    lw   a1, 20(sp)
    lw   a2, 16(sp)
    lw   t0, 12(sp)
    addi sp, sp, 32

    # Recompute split boundaries for merge
    srli a4, a1, 1
    slli a5, a4, 2
    add  a6, a0, a5
    addi a7, a6, -4

    # Fall through to Merge


Merge:
    # LEFT  half: first=a0, last=a7
    # RIGHT half: first=a6, last=a2

    add  t1, a0, x0        # t1 = left ptr
    add  t2, a6, x0        # t2 = right ptr
    add  t4, a7, x0        # t4 = left end
    add  t5, a2, x0        # t5 = right end

    lui  t6, %hi(temp)
    addi t6, t6, %lo(temp)
    add  t3, t6, x0        # t3 = temp write ptr

MergeLoopCheck:
    bltu t4, t1, CopyRightRemainder   # left exhausted
    bltu t5, t2, CopyLeftRemainder    # right exhausted

    lw   a3, 0(t1)         # left value
    lw   a5, 0(t2)         # right value

    blt  a5, a3, TakeRight

TakeLeft:
    sw   a3, 0(t3)
    addi t1, t1, 4
    addi t3, t3, 4
    beq  x0, x0, MergeLoopCheck

TakeRight:
    sw   a5, 0(t3)
    addi t2, t2, 4
    addi t3, t3, 4
    beq  x0, x0, MergeLoopCheck


CopyLeftRemainder:
    bltu t4, t1, CopyBackStart
CopyLeftLoop:
    lw   a3, 0(t1)
    sw   a3, 0(t3)
    addi t1, t1, 4
    addi t3, t3, 4
    bgeu t4, t1, CopyLeftLoop
    beq  x0, x0, CopyBackStart


CopyRightRemainder:
    bltu t5, t2, CopyBackStart
CopyRightLoop:
    lw   a5, 0(t2)
    sw   a5, 0(t3)
    addi t2, t2, 4
    addi t3, t3, 4
    bgeu t5, t2, CopyRightLoop


CopyBackStart:
    lui  t6, %hi(temp)
    addi t6, t6, %lo(temp)

    add  t1, a0, x0
    add  t2, a1, x0

CopyBackLoop:
    beq  t2, x0, MergeDone
    lw   a3, 0(t6)
    sw   a3, 0(t1)
    addi t6, t6, 4
    addi t1, t1, 4
    addi t2, t2, -1
    beq  x0, x0, CopyBackLoop


MergeDone:
MergeDoneReturn:
    jalr x0, 0(ra)