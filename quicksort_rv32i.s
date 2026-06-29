# =====================================================================
# 1. INICIALIZACIÓN DEL ARREGLO (Dir Base = 0)
# =====================================================================
add  a0, x0, x0       # a0 = Dirección base = 0
addi t0, x0, 9
sw   t0, 0(a0)        # arr[0] = 9
addi t0, x0, 4
sw   t0, 4(a0)        # arr[1] = 4
addi t0, x0, 7
sw   t0, 8(a0)        # arr[2] = 7
addi t0, x0, 2
sw   t0, 12(a0)       # arr[3] = 2
addi t0, x0, 8
sw   t0, 16(a0)       # arr[4] = 8

# =====================================================================
# 2. EJECUCIÓN DEL ALGORITMO (QUICKSORT)
# =====================================================================
addi sp, x0, 180      # sp = 180 (lejos del arreglo y de la dir 200)
add  a1, x0, x0       # a1 = low = 0
addi a2, x0, 4        # a2 = high = 4 
jal  ra, quicksort    # Llamar a quicksort

# =====================================================================
# 3. LECTURA PARA COMPROBACIÓN EN WAVEFORM
# =====================================================================
# Se cargarán en orden: [2, 4, 7, 8, 9]
lw   t0, 0(a0)
lw   t1, 4(a0)
lw   t2, 8(a0)
lw   t3, 12(a0)
lw   t4, 16(a0)

# =====================================================================
# 4. GUARDADO DE CONTROL Y BUCLE FIN
# =====================================================================
sw   a0, 200(x0)      # Trigger para el testbench
loop_fin:
jal  x0, loop_fin     # Bucle infinito de seguridad

# =====================================================================
# FUNCIÓN: quicksort (a0 = base, a1 = low, a2 = high)
# =====================================================================
quicksort:
    bge  a1, a2, quicksort_end
    
    # Push al Stack
    addi sp, sp, -20
    sw   ra, 16(sp)
    sw   a0, 12(sp)
    sw   a1, 8(sp)
    sw   a2, 4(sp)

    # Partition
    jal  ra, partition
    sw   a3, 0(sp)

    # Llamada Recursiva Izquierda (low a pi - 1)
    lw   a0, 12(sp)
    lw   a1, 8(sp)
    addi a2, a3, -1
    jal  ra, quicksort

    # Llamada Recursiva Derecha (pi + 1 a high)
    lw   a0, 12(sp)
    lw   a3, 0(sp)
    addi a1, a3, 1
    lw   a2, 4(sp)
    jal  ra, quicksort

    # Pop del Stack
    lw   ra, 16(sp)
    addi sp, sp, 20
quicksort_end:
    jalr x0, ra, 0

# =====================================================================
# FUNCIÓN: partition (Retorna el pivote en a3)
# =====================================================================
partition:
    slli t0, a2, 2
    add  t0, a0, t0
    lw   t1, 0(t0)               # t1 = arr[high] (Pivote)

    addi t2, a1, -1              # t2 = i
    add  t3, x0, a1              # t3 = j

partition_loop:
    bge  t3, a2, partition_end

    slli t4, t3, 2               
    add  t4, a0, t4
    lw   t5, 0(t4)               # t5 = arr[j]

    blt  t1, t5, partition_next  

    addi t2, t2, 1               # i++
    
    slli t6, t2, 2               
    add  t6, a0, t6
    lw   t0, 0(t6)               # temp = arr[i]
    sw   t5, 0(t6)               # arr[i] = arr[j]
    sw   t0, 0(t4)               # arr[j] = temp

partition_next:
    addi t3, t3, 1               # j++
    jal  x0, partition_loop

partition_end:
    addi t2, t2, 1               # i++

    slli t6, t2, 2
    add  t6, a0, t6
    lw   t0, 0(t6)               # temp = arr[i]

    slli t4, a2, 2
    add  t4, a0, t4
    
    sw   t1, 0(t6)               # arr[i] = pivote
    sw   t0, 0(t4)               # arr[high] = temp

    add  a3, x0, t2              # return i
    jalr x0, ra, 0