.option rvc         # Habilita la compresión de instrucciones (RVC)
    .text               # Sección de código
    .align 1            # Alineación a 2 bytes obligatoria para RVC
    .global _start

_start:
    # --- 1. Preparación del Entorno (Environment Setup) ---
    lui sp, 0x1         # Inicializar el Stack Pointer en 0x1000 (Dirección alta)
    
    # Cargar direcciones base de las matrices en registros RVC válidos (x8-x15)
    la a0, matrix_A     # a0 = Puntero a Matriz A
    la a1, matrix_B     # a1 = Puntero a Matriz B
    la a2, matrix_C     # a2 = Puntero a Matriz C (Destino)

    # --- 2. Ejecución de la Prueba ---
    c.jal matrix_mul    # Llamada comprimida a la subrutina

    # --- 3. Fin de la Simulación ---
end_matrix_program:
    c.j end_matrix_program  # Bucle infinito para detener la simulación


# =====================================================================
# Subrutina: matrix_mul
# Registros RVC restringidos utilizados: a0-a5, s0-s1 (x8-x15)
# =====================================================================
matrix_mul:
    # --- Prólogo ---
    c.addi sp, -16
    c.swsp ra, 12(sp)   # Salvar dirección de retorno
    c.swsp s0, 8(sp)    # Salvar registros callee-saved
    c.swsp s1, 4(sp)

    # Definir N = 4 (en a3)
    c.sub a3, a3
    c.addi a3, 4

    # i = 0 (en a4)
    c.sub a4, a4        

loop_i:
    # Condición: si i == N, terminar bucle i
    c.add s0, a3
    c.sub s0, a4
    c.beqz s0, end_i    #

    # j = 0 (en a5)
    c.sub a5, a5        

loop_j:
    # Condición: si j == N, terminar bucle j
    c.sub s0, s0
    c.add s0, a3
    c.sub s0, a5
    c.beqz s0, end_j

    # k = 0 (en s1)
    c.sub s1, s1        
    
    # Calcular dirección base de C[i][j]: desplazamiento = (i * 4 + j) * 4 bytes
    add t0, a4, x0      # t0 = i (Instrucción estándar de 32 bits)
    c.slli t0, 2        # t0 = i * 4 (Usa c.slli permitido en cualquier GPR)
    add t0, t0, a5      # t0 = (i * 4) + j
    c.slli t0, 2        # t0 = ((i * 4) + j) * 4 (conversión a bytes)
    add t1, a2, t0      # t1 = &C[i][j]
    
    # Inicializar acumulador de la suma de productos (t2 = 0)
    sub t2, t2, t2      

loop_k:
    # Condición: si k == N, terminar bucle k
    c.sub s0, s0
    c.add s0, a3
    c.sub s0, s1
    c.beqz s0, end_k

    # Calcular dirección y cargar A[i][k]: desplazamiento = (i * 4 + k) * 4
    add t3, a4, x0      
    c.slli t3, 2        
    add t3, t3, s1      # + k
    c.slli t3, 2        # convertir a bytes
    add t3, a0, t3      # t3 = &A[i][k]
    lw t4, 0(t3)        # t4 = valor de A[i][k]

    # Calcular dirección y cargar B[k][j]: desplazamiento = (k * 4 + j) * 4
    add t5, s1, x0      
    c.slli t5, 2        
    add t5, t5, a5      # + j
    c.slli t5, 2        # convertir a bytes
    add t5, a1, t5      # t5 = &B[k][j]
    lw t6, 0(t5)        # t6 = valor de B[k][j]

    # --- Multiplicación por Software (Sumas Sucesivas) ---
    # Multiplica t4 * t6. El resultado acumulado se guarda temporalmente en t5.
    sub t5, t5, t5      # t5 = 0
    add t3, t6, x0      # Clonar el multiplicador (t6) en t3 para la cuenta regresiva
soft_mul_loop:
    beq t3, x0, soft_mul_end  # Salto condicional base de 32 bits
    add t5, t5, t4      # Sumar el multiplicando
    addi t3, t3, -1     # Decrementar contador
    j soft_mul_loop     #
soft_mul_end:

    # Acumular el producto obtenido en el registro total t2
    add t2, t2, t5      

    # k++
    c.addi s1, 1        
    c.j loop_k          # Salto incondicional comprimido

end_k:
    # Almacenar el resultado final calculado en la celda C[i][j] de la memoria
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
    c.lwsp ra, 12(sp)   # Restaurar registros desde el Stack Pointer
    c.lwsp s0, 8(sp)
    c.lwsp s1, 4(sp)
    c.addi sp, 16       # Liberar espacio del stack
    c.jr ra             # Retorno

# =====================================================================
# Área de Datos (Data Memory)
# =====================================================================
    .data
    .align 2            # Alineación estricta de palabras de 32 bits (4 bytes)
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
    .zero 64            # Reserva 64 bytes (16 words inicializadas en 0)
