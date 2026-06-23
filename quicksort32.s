.text
    .align 2
    .global _start

_start:
    lui sp, 0x1         
    la a0, array_data   
    sub a1, a1, a1      
    sub a2, a2, a2
    addi a2, a2, 5      

    jal ra, quicksort   

end_sort_program:
    jal x0, end_sort_program

# =====================================================================
# Subrutina: quicksort (Pura 32 bits)
# =====================================================================
quicksort:
    sub s0, s0, s0
    add s0, a2, x0
    sub s0, s0, a1
    
    beq s0, x0, qs_end  

    # --- Prólogo ---
    addi sp, sp, -16
    sw ra, 12(sp)       
    sw a1, 8(sp)        
    sw a2, 4(sp)        

    # --- Partición ---
    add t0, a2, x0      
    slli t0, t0, 2      
    add t0, a0, t0      
    lw a3, 0(t0)        

    add a4, a1, x0      
    addi a4, a4, -1       

    add a5, a1, x0      

qs_partition_loop:
    sub s0, s0, s0
    add s0, a2, x0
    sub s0, s0, a5
    beq s0, x0, qs_partition_end

    add t1, a5, x0
    slli t1, t1, 2
    add t1, a0, t1      
    lw s0, 0(t1)        

    sub t2, s0, a3      
    bge t2, x0, qs_j_inc 

    addi a4, a4, 1

    add t3, a4, x0
    slli t3, t3, 2
    add t3, a0, t3      
    lw t4, 0(t3)        

    sw s0, 0(t3)        
    sw t4, 0(t1)        

qs_j_inc:
    addi a5, a5, 1        
    jal x0, qs_partition_loop

qs_partition_end:
    addi a4, a4, 1        
    
    add t3, a4, x0
    slli t3, t3, 2
    add t3, a0, t3      
    lw t4, 0(t3)        
    
    sw a3, 0(t3)        
    sw t4, 0(t0)        

    sw a4, 0(sp)        

    # --- Recursión Izquierda ---
    lw a1, 8(sp)        
    add a2, a4, x0      
    addi a2, a2, -1       
    jal ra, quicksort

    # --- Recursión Derecha ---
    lw a4, 0(sp)        
    lw a2, 4(sp)        
    add a1, a4, x0      
    addi a1, a1, 1        
    jal ra, quicksort

    # --- Epílogo ---
    lw ra, 12(sp)       
    addi sp, sp, 16       

qs_end:
    jalr x0, ra, 0      

    .data
    .align 2
array_data:
    .word 45, 7, 99, 23, 2, 18
