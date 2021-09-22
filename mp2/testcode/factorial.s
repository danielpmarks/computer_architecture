factorial.s:
 .align 4
 .section .text
 .globl factorial

 factorial:
         # Register a0 holds the input value
         # Register t0-t6 are caller-save, so you may use them without saving
         # Return value need to be put in register a0
        addi t1, a0, 0        # Put the starting value in reg a1
        addi t0, x0, 1         # Put 1 in reg a2
        sub  t1, t1, t0      # Reg a1 = a1 - 1
        beq  a0, t0, ret      # If multiplier is 1, jump to finish

    fact_loop:
        addi t3, t1, 0        # Put current multiplier into t3
        jal t5, multiply       # Call multiply subroutine
        sub t1, t1, t0       # Decrement factorial counter
        bne t1, t0, fact_loop # If multiplier is not equal to 1, loop back
        jal t5, ret

    multiply:
        addi t4, a0, 0        # Save beginning value
        sub  t3, t3, t0      # Subtract 1 from multiplier
       mult_loop:
        add a0, a0, t4       # Add value once
        sub t3, t3, t0       # Decrement multiplier count
        bne t3, x0, mult_loop  # Loop back if counter not equal to zero
        jalr t5, 0             # If loop is over, return to factorial
   
 ret:
         jr ra # Register ra holds the return address
 .section .rodata