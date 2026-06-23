.option rvc
    .text
    .align 1
    .global _start

_start:
# void matrix_mul_4x4(int* A (a0), int* B (a1), int* C (a2))
# Asumimos N = 4. Registros restringidos RVC: a0-a5, s0-s1 (x8-x15)

matrix_mul:
    # --- Prólogo ---
    c.addi sp, -16
    c.swsp ra, 12(sp)
    c.swsp s0, 8(sp)
    c.swsp s1, 4(sp)

    # N = 4 (en a3)
    c.sub a3, a3
    c.addi a3, 4

    # i = 0 (en a4)
    c.sub a4, a4        

loop_i:
    # Verificamos si i == N
    c.add s0, a3
    c.sub s0, a4
    c.beqz s0, end_i

    # j = 0 (en a5)
    c.sub a5, a5        

loop_j:
    # Verificamos si j == N
    c.sub s0, s0
    c.add s0, a3
    c.sub s0, a5
    c.beqz s0, end_j

    # k = 0 (en s1)
    c.sub s1, s1        
    
    # Calcular C[i][j] base: idx = (i * 4 + j) * 4
    add t0, a4, x0      # t0 = i
    c.slli t0, 2        # t0 = i * 4 (Equivalente a mul t0, i, 4)
    add t0, t0, a5      # t0 = (i * 4) + j
    c.slli t0, 2        # t0 = t0 * 4 bytes
    add t1, a2, t0      # t1 = &C[i][j]
    
    # Inicializar sumador (t2 = 0)
    sub t2, t2, t2      

loop_k:
    # Verificamos si k == N
    c.sub s0, s0
    c.add s0, a3
    c.sub s0, s1
    c.beqz s0, end_k

    # Cargar A[i][k]: idxA = (i * 4 + k) * 4
    add t3, a4, x0      # t3 = i
    c.slli t3, 2        # t3 = i * 4
    add t3, t3, s1      # t3 = (i * 4) + k
    c.slli t3, 2        # * 4 bytes
    add t3, a0, t3      # &A[i][k]
    lw t4, 0(t3)

    # Cargar B[k][j]: idxB = (k * 4 + j) * 4
    add t5, s1, x0      # t5 = k
    c.slli t5, 2        # t5 = k * 4
    add t5, t5, a5      # t5 = (k * 4) + j
    c.slli t5, 2        # * 4 bytes
    add t5, a1, t5      # &B[k][j]
    lw t6, 0(t5)        

    # Simular A * B usando sumas sucesivas (ya que no hay 'mul')
    # t4 = multiplicando, t6 = multiplicador, t5 = acumulador temporal
    sub t5, t5, t5      # t5 = 0
    add t3, t6, x0      # Copia del multiplicador para el bucle
soft_mul_loop:
    beq t3, x0, soft_mul_end
    add t5, t5, t4      # Acumulamos
    addi t3, t3, -1     # multiplicador--
    j soft_mul_loop     # Usamos salto estándar de 32 bits para variabilidad
soft_mul_end:

    # Acumular en t2 el resultado de A*B
    add t2, t2, t5      

    # k++
    c.addi s1, 1        
    c.j loop_k

end_k:
    # Guardar resultado en C[i][j]
    sw t2, 0(t1)

    # j++
    c.addi a5, 1
    c.j loop_j

end_j:
    # i++
    c.addi a4, 1
    c.j loop_i

end_i:
    # --- Epílogo ---
    c.lwsp ra, 12(sp)
    c.lwsp s0, 8(sp)
    c.lwsp s1, 4(sp)
    c.addi sp, 16
    c.jr ra
    