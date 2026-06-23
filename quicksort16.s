.option rvc
    .text
    .align 1
    .global _start

_start:
    # --- 1. Preparación del Entorno (Environment Setup) ---
    lui sp, 0x1         # Inicializar el Stack Pointer en 0x1000

    # Configuración de los parámetros iniciales de la función
    la a0, array_data   # a0 = Puntero base del arreglo
    c.sub a1, a1        # a1 = low = 0 (Índice de inicio)
    c.sub a2, a2
    c.addi a2, 5        # a2 = high = 5 (Índice final para 6 elementos: 0 a 5)

    # --- 2. Ejecución de la Prueba ---
    c.jal quicksort     # Llamada recursiva inicial

    # --- 3. Fin de la Simulación ---
end_sort_program:
    c.j end_sort_program


# =====================================================================
# Subrutina: quicksort(int* arr (a0), int low (a1), int high (a2))
# =====================================================================
quicksort:
    # Condición base: calcular s0 = high - low
    c.sub s0, s0
    c.add s0, a2
    c.sub s0, a1
    
    # Si high <= low, la resta dará 0 o un valor negativo. 
    # Terminamos la ejecución de esta rama de la recursión.
    c.beqz s0, qs_end   #

    # --- Prólogo ---
    c.addi sp, -16
    c.swsp ra, 12(sp)   # Almacenar dirección de retorno
    c.swsp a1, 8(sp)    # Almacenar el índice low actual
    c.swsp a2, 4(sp)    # Almacenar el índice high actual

    # --- Lógica del Algoritmo de Partición (Lomuto) ---
    # Tomar el pivote: pivote = arr[high]
    add t0, a2, x0      
    c.slli t0, 2        # t0 = high * 4 bytes
    add t0, a0, t0      # t0 = &arr[high]
    lw a3, 0(t0)        # a3 = Valor del Pivote

    # Variable i: a4 = low - 1
    add a4, a1, x0      
    c.addi a4, -1       

    # Variable j: a5 = low
    add a5, a1, x0      

qs_partition_loop:
    # Condición de salida del bucle de partición: si j == high
    c.sub s0, s0
    c.add s0, a2
    c.sub s0, a5
    c.beqz s0, qs_partition_end

    # Cargar arr[j] en s0
    add t1, a5, x0
    c.slli t1, 2
    add t1, a0, t1      # t1 = &arr[j]
    lw s0, 0(t1)        # s0 = arr[j]

    # Comparación: si arr[j] >= pivote, saltar el intercambio e ir al siguiente ciclo
    sub t2, s0, a3      # t2 = arr[j] - pivote
    bge t2, x0, qs_j_inc # Salto condicional de 32 bits

    # En caso contrario (arr[j] < pivote): i++
    c.addi a4, 1

    # Realizar el intercambio (Swap) entre arr[i] y arr[j]
    add t3, a4, x0
    c.slli t3, 2
    add t3, a0, t3      # t3 = &arr[i]
    lw t4, 0(t3)        # t4 = arr[i]

    sw s0, 0(t3)        # arr[i] = arr[j]
    sw t4, 0(t1)        # arr[j] = arr[i] anterior

qs_j_inc:
    c.addi a5, 1        # j++
    c.j qs_partition_loop

qs_partition_end:
    # Colocar el pivote en su posición final: Swap entre arr[i+1] y arr[high]
    c.addi a4, 1        # a4 = Índice definitivo de la partición (pi)
    
    add t3, a4, x0
    c.slli t3, 2
    add t3, a0, t3      # t3 = &arr[pi]
    lw t4, 0(t3)        # t4 = arr[pi]
    
    sw a3, 0(t3)        # arr[pi] = pivote
    sw t4, 0(t0)        # arr[high] = arr[pi] antiguo

    # Guardar el índice de partición calculado en la pila antes de la recursión
    c.swsp a4, 0(sp)    #

    # --- Llamada de Recursión Izquierda: quicksort(arr, low, pi - 1) ---
    c.lwsp a1, 8(sp)    # Restaurar el low original de este marco de ejecución
    add a2, a4, x0      
    c.addi a2, -1       # high = pi - 1
    c.jal quicksort

    # --- Llamada de Recursión Derecha: quicksort(arr, pi + 1, high) ---
    c.lwsp a4, 0(sp)    # Recuperar el índice de partición (pi) de la pila
    c.lwsp a2, 4(sp)    # Recuperar el high original de este marco de ejecución
    add a1, a4, x0      
    c.addi a1, 1        # low = pi + 1
    c.jal quicksort

    # --- Epílogo ---
    c.lwsp ra, 12(sp)   # Restaurar el puntero de retorno original
    c.addi sp, 16       # Devolver espacio reservado de memoria

qs_end:
    c.jr ra             # Retorno

# =====================================================================
# Área de Datos (Data Memory)
# =====================================================================
    .data
    .align 2
array_data:
    .word 45            # Elemento 0
    .word 7             # Elemento 1
    .word 99            # Elemento 2
    .word 23            # Elemento 3
    .word 2             # Elemento 4
    .word 18            # Elemento 5
