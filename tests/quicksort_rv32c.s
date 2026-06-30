# =====================================================================
# 1. INICIALIZACIÓN (Usando c.sw con base a0 y temp s0)
# =====================================================================
add  a0, x0, x0       # a0 = 0 (Registro C compatible)
addi s0, x0, 8
c.sw s0, 0(a0)        # arr[0] = 9 (Instrucción de 16-bits)
addi s0, x0, 3
c.sw s0, 4(a0)
addi s0, x0, 6
c.sw s0, 8(a0)
addi s0, x0, 1
c.sw s0, 12(a0)
addi s0, x0, 7
c.sw s0, 16(a0)

# =====================================================================
# 2. EJECUCIÓN DEL ALGORITMO
# =====================================================================
addi sp, x0, 180      
add  a1, x0, x0       
addi a2, x0, 4        
c.jal quicksort       # c.jal (Instrucción de 16-bits)

# =====================================================================
# 3. LECTURA (Usando c.lw)
# =====================================================================
c.lw s0, 0(a0)
c.lw s1, 4(a0)
c.lw a3, 8(a0)
c.lw a4, 12(a0)
c.lw a5, 16(a0)

# =====================================================================
# 4. GUARDADO DE CONTROL
# =====================================================================
sw   a0, 200(x0)      # (Obligatorio 32-bits porque x0 no es C-compatible)
loop_fin:
c.j  loop_fin         # c.j en lugar de jal x0, label

# =====================================================================
# FUNCIÓN: quicksort
# =====================================================================
quicksort:
    bge  a1, a2, quicksort_end
    
    # Push (Uso agresivo de c.swsp reduce a la mitad el tamaño del push)
    addi sp, sp, -20
    c.swsp ra, 16(sp)
    c.swsp a0, 12(sp)
    c.swsp a1, 8(sp)
    c.swsp a2, 4(sp)

    c.jal partition
    c.swsp a3, 0(sp)

    # Recursividad Izquierda
    c.lwsp a0, 12(sp)
    c.lwsp a1, 8(sp)
    add  a2, x0, a3
    c.addi a2, -1         
    c.jal quicksort

    # Recursividad Derecha
    c.lwsp a0, 12(sp)
    c.lwsp a3, 0(sp)
    add  a1, x0, a3
    c.addi a1, 1
    c.lwsp a2, 4(sp)
    c.jal quicksort

    # Pop
    c.lwsp ra, 16(sp)
    addi sp, sp, 20
quicksort_end:
    c.jr ra               # c.jr (16-bits)

# =====================================================================
# FUNCIÓN: partition
# =====================================================================
partition:
    # Usamos a4(i) y a5(j) para compatibilidad RV32C
    add  a3, x0, a2       
    c.slli a3, 2          # c.slli (16-bits)
    c.add  a3, a0         # c.add (16-bits)
    c.lw   s1, 0(a3)      # s1 = arr[high] (Pivote)

    add  a4, x0, a1       
    c.addi a4, -1         # i = low - 1
    add  a5, x0, a1       # j = low

partition_loop:
    bge  a5, a2, partition_end

    add  a3, x0, a5       
    c.slli a3, 2
    c.add  a3, a0         
    c.lw   s0, 0(a3)      # s0 = arr[j]

    blt  s1, s0, partition_next  

    c.addi a4, 1          # i++
    
    add  a1, x0, a4       
    c.slli a1, 2
    c.add  a1, a0         # a1 = &arr[i] (a1 es reutilizado aquí)
    
    lw   t0, 0(a1)        # t0 = arr[i] (mezcla con 32-bits por límite de registros)
    c.sw s0, 0(a1)        # arr[i] = arr[j]
    sw   t0, 0(a3)        # arr[j] = temp

partition_next:
    c.addi a5, 1          # j++
    c.j  partition_loop   # c.j en vez de jal

partition_end:
    c.addi a4, 1          # i++

    add  a1, x0, a4       
    c.slli a1, 2
    c.add  a1, a0         
    
    add  a3, x0, a2
    c.slli a3, 2
    c.add  a3, a0         
    
    lw   t0, 0(a1)        
    c.sw s1, 0(a1)        # arr[i] = pivote
    sw   t0, 0(a3)        # arr[high] = temp

    add  a3, x0, a4       # return i
    c.jr ra