.option rvc         # Habilita la compresión de instrucciones
    .text               # Sección de código
    .align 1            # Alineación estricta a 2 bytes para RVC
    .global _start

_start:
    # --- Configuración inicial del entorno ---
    # Inicializamos el Stack Pointer (sp/x2) en una dirección alta de memoria
    # Asumiendo que tu Data Memory permite escrituras en direcciones como 0x1000
    lui sp, 0x1         # sp = 0x1000 (Instrucción de 32 bits estándar)
    
    # Cargar la dirección de la raíz del árbol en a0 (registro x10, restringido RVC)
    la a0, tree_root    # Macro que se expande a instrucciones estándar
    
    # Llamada a la función recursiva
    c.jal count_nodes   # Salto comprimido
    
    # Al finalizar, 'a0' contendrá el número total de nodos (Esperado: 5)
    # Bucle infinito para atrapar el final de la simulación
end_program:
    c.j end_program     # Salto incondicional RVC


# =====================================================================
# int count_nodes(Node* root (a0))
# Retorna en a0 la cantidad total de nodos.
# Registros restringidos usados: a0, s0 (x8), s1 (x9)
# =====================================================================
count_nodes:
    # Condición base: if (root == NULL) return 0;
    c.beqz a0, return_zero      #

    # --- Prólogo ---
    # Reservar 16 bytes en el stack (obligatorio múltiplo de 16 para ABI)
    c.addi sp, -16              
    c.swsp ra, 12(sp)           # Guardar Return Address
    c.swsp s0, 8(sp)            # Guardar s0 (se usará para el puntero al nodo)
    c.swsp s1, 4(sp)            # Guardar s1 (se usará como acumulador)

    # Copiar puntero root (a0) a s0
    add s0, a0, x0              # Instrucción 32-bits estándar para alternar formatos

    # Inicializar el acumulador s1 en 1 (contamos el nodo actual)
    c.sub s1, s1                # s1 = 0
    c.addi s1, 1                # s1 = 1

    # --- Recursión Subárbol Izquierdo ---
    # Cargar puntero izquierdo: root->left está en el offset 4
    c.lw a0, 4(s0)              # c.lw usa rd'=a0, rs1'=s0. Ambos válidos en x8-x15
    c.jal count_nodes           # count_nodes(root->left)
    
    # Acumular resultado: s1 = s1 + a0
    c.add s1, a0                

    # --- Recursión Subárbol Derecho ---
    # Cargar puntero derecho: root->right está en el offset 8
    c.lw a0, 8(s0)              # Offset 8 es válido para el formato c.lw
    c.jal count_nodes           # count_nodes(root->right)

    # Acumular resultado final en a0 (registro de retorno): a0 = a0 + s1
    c.add a0, s1                #

    # --- Epílogo ---
    c.lwsp ra, 12(sp)           
    c.lwsp s0, 8(sp)
    c.lwsp s1, 4(sp)
    c.addi sp, 16               

    # Retorno al llamador
    c.jr ra                     #

return_zero:
    # Si a0 era 0 (NULL), asegurar el retorno en 0
    c.sub a0, a0
    c.jr ra

# =====================================================================
# Área de Datos: Árbol Binario de Prueba (5 nodos)
# =====================================================================
    .data
    .align 2                    # Alineación a 4 bytes para datos (words)
tree_root:
    .word 100                   # Valor del nodo
    .word node_l                # Puntero izquierdo
    .word node_r                # Puntero derecho
node_l:
    .word 200
    .word node_ll
    .word 0                     # NULL
node_r:
    .word 300
    .word 0                     # NULL
    .word node_rr
node_ll:
    .word 400
    .word 0
    .word 0
node_rr:
    .word 500
    .word 0
    .word 0
