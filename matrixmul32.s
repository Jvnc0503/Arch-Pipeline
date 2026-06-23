.text
    .align 2            # Alineación estricta a 4 bytes (32 bits)
    .global _start

_start:
    # --- 1. Preparación del Entorno ---
    lui sp, 0x1         
    la a0, matrix_A     
    la a1, matrix_B     
    la a2, matrix_C     

    # --- 2. Ejecución de la Prueba ---
    jal ra, matrix_mul  # Equivalente 32-bits de c.jal

    # --- 3. Fin de la Simulación ---
end_matrix_program:
    jal x0, end_matrix_program  # Equivalente 32-bits de c.j


# =====================================================================
# Subrutina: matrix_mul (Pura 32 bits)
# =====================================================================
matrix_mul:
    # --- Prólogo ---
    addi sp, sp, -16    # Equivalente de c.addi sp, -16
    sw ra, 12(sp)       # Equivalente de c.swsp
    sw s0, 8(sp)
    sw s1, 4(sp)

    # N = 4
    sub a3, a3, a3      # Limpiar registro
    addi a3, a3, 4      

    # i = 0
    sub a4, a4, a4      

loop_i:
    add s0, a3, x0
    sub s0, s0, a4
    beq s0, x0, end_i   # Equivalente de c.beqz s0, end_i

    # j = 0
    sub a5, a5, a5      

loop_j:
    sub s0, s0, s0
    add s0, a3, x0
    sub s0, s0, a5
    beq s0, x0, end_j

    # k = 0
    sub s1, s1, s1      
    
    # &C[i][j]
    add t0, a4, x0      
    slli t0, t0, 2      # Equivalente de c.slli
    add t0, t0, a5      
    slli t0, t0, 2      
    add t1, a2, t0      
    
    sub t2, t2, t2      

loop_k:
    sub s0, s0, s0
    add s0, a3, x0
    sub s0, s0, s1
    beq s0, x0, end_k

    # &A[i][k]
    add t3, a4, x0      
    slli t3, t3, 2      
    add t3, t3, s1      
    slli t3, t3, 2      
    add t3, a0, t3      
    lw t4, 0(t3)        

    # &B[k][j]
    add t5, s1, x0      
    slli t5, t5, 2      
    add t5, t5, a5      
    slli t5, t5, 2      
    add t5, a1, t5      
    lw t6, 0(t5)        

    # Multiplicación por Software
    sub t5, t5, t5      
    add t3, t6, x0      
soft_mul_loop:
    beq t3, x0, soft_mul_end
    add t5, t5, t4      
    addi t3, t3, -1     
    jal x0, soft_mul_loop
soft_mul_end:

    add t2, t2, t5      

    # k++
    addi s1, s1, 1      # Equivalente de c.addi s1, 1
    jal x0, loop_k

end_k:
    sw t2, 0(t1)
    addi a5, a5, 1
    jal x0, loop_j

end_j:
    addi a4, a4, 1
    jal x0, loop_i

end_i:
    # --- Epílogo ---
    lw ra, 12(sp)       # Equivalente de c.lwsp
    lw s0, 8(sp)
    lw s1, 4(sp)
    addi sp, sp, 16     
    jalr x0, ra, 0      # Equivalente de c.jr ra

    .data
    .align 2            
matrix_A:
    .word 1, 2, 3, 4
    .word 5, 6, 7, 8
    .word 1, 1, 1, 1
    .word 2, 0, 2, 0

matrix_B:
    .word 1, 0, 0, 0
    .word 0, 1, 0, 0
    .word 0, 0, 1, 0
    .word 0, 0, 0, 1

matrix_C:
    .zero 64
