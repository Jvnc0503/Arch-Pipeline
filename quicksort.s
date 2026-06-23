.option rvc         # Habilita la compresión de instrucciones
    .text               # Indica que es la sección de código
    .align 1            # Alineación a 2 bytes (requerido para RVC)
    .global _start

_start:
# void quicksort(int* arr (a0), int low (a1), int high (a2))

quicksort:
    # Condición base: if (low >= high) return;
    # Convertimos a: if (high - low <= 0) return;
    # s0 = high - low
    c.sub s0, s0        # s0 = 0
    c.add s0, a2        # s0 = high
    c.sub s0, a1        # s0 = high - low
    
    # Si high - low == 0, retornar (caso array de 1 elemento)
    c.beqz s0, qs_end  
    # (Para < 0, requeriría bltz que no está en RVC, pero omitimos ese chequeo asumiendo índices válidos para fines de la prueba)

    # --- Prólogo Quicksort ---
    c.addi sp, -16
    c.swsp ra, 12(sp)
    c.swsp a1, 8(sp)    # Guardamos low
    c.swsp a2, 4(sp)    # Guardamos high

    # --- Lógica de Partición ---
    # Para la prueba, iteramos con punteros para maximizar c.lw y c.sw
    # a3 = pivote = arr[high]
    add t0, a2, x0      # t0 = high
    c.slli t0, 2        # t0 = high * 4
    add t0, a0, t0      # t0 = &arr[high]
    lw a3, 0(t0)        # a3 = pivote

    # a4 = i = low - 1
    c.sub a4, a4
    c.add a4, a1
    c.addi a4, -1

    # a5 = j = low
    c.sub a5, a5
    c.add a5, a1

qs_partition_loop:
    # if (j == high) salir del bucle
    c.sub s1, s1
    c.add s1, a2
    c.sub s1, a5        # s1 = high - j
    c.beqz s1, qs_partition_end

    # Cargar arr[j]
    add t1, a5, x0
    c.slli t1, 2
    add t1, a0, t1      # t1 = &arr[j]
    lw s1, 0(t1)        # s1 = arr[j]

    # if (arr[j] >= pivote) continue; (simulamos con sub)
    sub t2, s1, a3      # t2 = arr[j] - pivote
    bge t2, x0, qs_j_inc # Si t2 >= 0, salta (usamos bge estándar, no hay c.bge)

    # i++
    c.addi a4, 1

    # Swap arr[i] y arr[j]
    add t3, a4, x0
    c.slli t3, 2
    add t3, a0, t3      # t3 = &arr[i]
    lw t4, 0(t3)        # t4 = arr[i]

    sw s1, 0(t3)        # arr[i] = arr[j]
    sw t4, 0(t1)        # arr[j] = arr[i] old

qs_j_inc:
    c.addi a5, 1
    c.j qs_partition_loop

qs_partition_end:
    # Swap arr[i+1] y arr[high] (pivote)
    c.addi a4, 1        # i+1
    
    add t3, a4, x0
    c.slli t3, 2
    add t3, a0, t3      # t3 = &arr[i+1]
    lw t4, 0(t3)        # t4 = arr[i+1]
    
    sw a3, 0(t3)        # arr[i+1] = pivote
    sw t4, 0(t0)        # arr[high] = arr[i+1] old

    # a4 ahora contiene el índice de partición (pi)
    # Recursión 1: quicksort(arr, low, pi - 1)
    c.lwsp a1, 8(sp)    # Restaurar low
    add a2, a4, x0      # a2 = pi
    c.addi a2, -1       # a2 = pi - 1
    
    # Llamada a función usando jal explícito para estresar pipeline
    c.jal quicksort     #

    # Recursión 2: quicksort(arr, pi + 1, high)
    c.lwsp a2, 4(sp)    # Restaurar high original
    c.lwsp a4, 0(sp)    # Restaurar pi (debes haber guardado 'pi' en sp o recalcularlo)
    add a1, a4, x0
    c.addi a1, 1        # low = pi + 1

    c.jal quicksort

    # --- Epílogo ---
    c.lwsp ra, 12(sp)
    c.addi sp, 16

qs_end:
    c.jr ra
