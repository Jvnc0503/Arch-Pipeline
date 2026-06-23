.text               
    .align 2            
    .global _start

_start:
    lui sp, 0x1         
    la a0, tree_root    
    
    jal ra, count_nodes 
    
end_program:
    jal x0, end_program 

# =====================================================================
# Subrutina: count_nodes (Pura 32 bits)
# =====================================================================
count_nodes:
    beq a0, x0, return_zero

    # --- Prólogo ---
    addi sp, sp, -16              
    sw ra, 12(sp)           
    sw s0, 8(sp)            
    sw s1, 4(sp)            

    add s0, a0, x0              

    sub s1, s1, s1              
    addi s1, s1, 1                

    # --- Recursión Subárbol Izquierdo ---
    lw a0, 4(s0)              
    jal ra, count_nodes       
    
    add s1, s1, a0                

    # --- Recursión Subárbol Derecho ---
    lw a0, 8(s0)              
    jal ra, count_nodes       

    add a0, s1, x0                

    # --- Epílogo ---
    lw ra, 12(sp)           
    lw s0, 8(sp)
    lw s1, 4(sp)
    addi sp, sp, 16               

    jalr x0, ra, 0

return_zero:
    sub a0, a0, a0
    jalr x0, ra, 0

    .data
    .align 2                    
tree_root:
    .word 100                   
    .word node_l                
    .word node_r                
node_l:
    .word 200
    .word node_ll
    .word 0                     
node_r:
    .word 300
    .word 0                     
    .word node_rr
node_ll:
    .word 400
    .word 0
    .word 0
node_rr:
    .word 500
    .word 0
    .word 0
