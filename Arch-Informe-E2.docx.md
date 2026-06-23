 			Arquitectura de Computadoras — Proyecto 2  
 

**Diseño e implementación de la extensión ’C’ (instrucciones comprimidas) de**

**RISC-V en un procesador pipelined**

 **Integrantes:** 

| APELLIDOS, NOMBRES | Participación |
| :---: | :---: |
| Thiago Gabriel Rivera Matta | 100%  |
| Jesús Valentín Niño Castañeda | 100%  |
| Reyes Medina, Jordinn Martin | 100%  |

**ASIGNATURA:** 

Arquitectura de Computadoras

**DOCENTE:**

Carlos Williams

      2026 \- 1

**ÍNDICE**

[**1\. Implementación de las Instrucciones	3**](#1.-implementación-de-las-instrucciones)

[1.1 Instrucciones Implementadas	3](#1.1-instrucciones-implementadas)

[1.2 Explicación Cambios del Código	4](#1.2-explicación-cambios-del-código)

[1\. El Módulo Descompresor (decompressor.v)	4](#1.-el-módulo-descompresor-\(decompressor.v\))

[2\. Adaptación del Datapath y Control del PC (datapath.v)	5](#2.-adaptación-del-datapath-y-control-del-pc-\(datapath.v\))

[3\. Fetch Desalineado en la Memoria de Instrucciones (imem.v)	6](#3.-fetch-desalineado-en-la-memoria-de-instrucciones-\(imem.v\))

[4\. Limpieza y Bloques de Ejecución (aludec.v y pipereg.v)	6](#4.-limpieza-y-bloques-de-ejecución-\(aludec.v-y-pipereg.v\))

[5\. Monitor Universal de Pruebas (testbench.v)	7](#5.-monitor-universal-de-pruebas-\(testbench.v\))

[1.1. Diagrama de el datapath final	7](#diagrama-de-el-datapath-final)

[**2\. Programa RVC : ISA	8**](#2.-programa-rvc-:-isa)

[2.1 Descripción del programa	8](#2.1-descripción-del-programa)

[2.2 Archivo .mem utilizado para pruebas de instrucciones	8](#2.2-archivo-.mem-utilizado-para-pruebas-de-instrucciones)

[**3\. Validación de cada una de las instrucciones	12**](#3.-validación-de-cada-una-de-las-instrucciones)

[3.1 Prueba de c.addi	12](#3.1-prueba-de-c.addi)

[3.2 Prueba de c.add	13](#3.2-prueba-de-c.add)

[3.3 Prueba de c.sub	13](#3.3-prueba-de-c.sub)

[3.4 Prueba de c.and	14](#3.4-prueba-de-c.and)

[3.5 Prueba de c.or	14](#3.5-prueba-de-c.or)

[3.6 Prueba de c.xor	14](#3.6-prueba-de-c.xor)

[3.7 Prueba de c.slli	15](#3.7-prueba-de-c.slli)

[3.8 Prueba de c.srli	15](#3.8-prueba-de-c.srli)

[3.9 Prueba de c.srai	16](#3.9-prueba-de-c.srai)

[3.10 Prueba de c.lui	16](#3.10-prueba-de-c.lui)

[4\. Waveforms de verificación	17](#4.-algoritmos-implementados)

[5\. Comparación antes y después de la implementación	17](#5.-comparativa-de-tamaño-de-programa)

[**6\. Conclusiones	17**](#6.-conclusiones)

[**Bibliografía	18**](#bibliografía)

# 

# **1\. Implementación de las Instrucciones** {#1.-implementación-de-las-instrucciones}

## **1.1 Instrucciones Implementadas** {#1.1-instrucciones-implementadas}

La implementación de la extensión  C incluye las instrucciones requeridas para ejecutar correctamente los programas de prueba. En el cuadro siguiente se resumen las instrucciones soportadas y su función principal.

| Instrucción | Formato | Operación principal | Uso en el proyecto |
| :---- | :---- | :---- | :---- |
| `c.addi` | I-type | Suma inmediata | Inicialización de registros y pruebas de datos |
| `c.add` | R-type | Suma de registros | Validación de forwarding y ejecución aritmética |
| `c.sub` | R-type | Resta de registros  | Verificación de operaciones aritméticas y comparaciones  |
| `c.and` | R-type | And entre registros | Validación de operaciones lógicas entre registros  |
| `c.or` | R-type | Or entre registros | Validación de operaciones lógicas entre registros  |
| `c.xor` | R-type | Xor entre registros | Validación de operaciones lógicas entre registros  |
| `c.slli` | I-type | Shift izquierdo lógico inmediato | Verificación de operaciones de desplazamiento con inmediatos |
| `c.srli` | I-type | Shift derecho lógico inmediato | Verificación de desplazamiento lógico hacia la derecha  |
| `c.srai` | I-type | Shift derecho aritmético inmediato | Verificación del manejo correcto del bit de signo  |
| `c.lui` | U-type | Cargar en el intermedio superior | Inicialización eficiente de constantes de 32 bits |

## **1.2 Explicación Cambios del Código** {#1.2-explicación-cambios-del-código}

### **1\. El Módulo Descompresor (decompressor.v)** {#1.-el-módulo-descompresor-(decompressor.v)}

El corazón de la extensión ’C’ es un traductor combinacional que toma instrucciones de 16 bits y las expande a sus equivalentes de 32 bits del ISA base de RISC-V en tiempo real. Se creó un módulo completamente nuevo (decompressor.v) que lee los bits menos significativos (op) y los bits de función (funct3) para determinar a qué cuadrante pertenece la instrucción comprimida y mapear los campos (como los registros restringidos x8-x15) a la codificación estándar de 32 bits.

```
module decompressor(
    input  wire [15:0] instr_c,
    output reg  [31:0] instr_32
);
    wire [1:0] op = instr_c[1:0];
    wire [2:0] funct3 = instr_c[15:13];

    // Expansión de registros comprimidos x8-x15
    wire [4:0] rs1_c = {2'b01, instr_c[9:7]};
    wire [4:0] rs2_c = {2'b01, instr_c[4:2]};

    always @* begin
        case (op)
            2'b00: begin /* Cuadrante 0: c.lw, c.sw */ end
            2'b01: begin /* Cuadrante 1: c.addi, c.jal, c.beqz, etc. */ end
            2'b10: begin /* Cuadrante 2: c.slli, c.lwsp, c.add, etc. */ end
            default: instr_32 = 32'h00000013; // NOP de seguridad
        endcase
    end
endmodule
```

### **2\. Adaptación del Datapath y Control del PC (datapath.v)** {#2.-adaptación-del-datapath-y-control-del-pc-(datapath.v)}

En el datapath original, el Program Counter (PC) siempre avanzaba sumando 4 bytes (PC \+ 4). Con la extensión ’C’, el salto del PC ahora es dinámico: debe sumar 2 si la instrucción actual es de 16 bits, o 4 si es de 32 bits. Además, se insertó el decompressor en la etapa de Fetch para que evalúe la instrucción entrante. Si la instrucción detectada es comprimida (evaluando si los últimos dos bits son distintos de 11), se pasa al registro de segmentación (IF/ID) la versión descomprimida; de lo contrario, pasa la instrucción original.

```
// Detección de instrucción comprimida
  wire is_compressed = (InstrF[1:0] != 2'b11); 

  // Instanciación del descompresor
  wire [31:0] InstrF_decomp;
  decompressor decomp (.instr_c(InstrF[15:0]), .instr_32(InstrF_decomp));

  // Selección de la instrucción final que pasará al pipeline
  wire [31:0] InstrF_final = is_compressed ? InstrF_decomp : InstrF;
  
  // Cálculo dinámico del salto del Program Counter
  wire [31:0] PCStep = is_compressed ? 32'd2 : 32'd4;
  adder pcaddstep(.a(PCF), .b(PCStep), .y(PCPlusStepF));

  // Actualización del registro IF/ID con la instrucción final y el PCStep
  pipereg r_if_id_instr (.clk(clk), .reset(reset), .en(~StallD), .clr(PCSrcE), .d(InstrF_final), .q(InstrD));
```

### **3\. Fetch Desalineado en la Memoria de Instrucciones (imem.v)** {#3.-fetch-desalineado-en-la-memoria-de-instrucciones-(imem.v)}

Dado que las instrucciones comprimidas ocupan 2 bytes (16 bits), el PC puede terminar apuntando a direcciones que terminan en 2 (por ejemplo, 0x...002, 0x...006), lo cual rompe el alineamiento estándar de palabras de 32 bits. Si una instrucción de 32 bits empieza en un límite de "half-word" desalineado, cruzará la frontera de la palabra de memoria actual. Para solucionarlo, se modificó la memoria de instrucciones para que concatene los 16 bits superiores de la palabra actual con los 16 bits inferiores de la siguiente palabra cuando detecte que la dirección está desalineada (a\[1\] \== 1).

```
wire [29:0] word_addr = a[31:2]; 
    wire        half_aligned = a[1]; // Detecta si termina en 2 (ej. 0x02)

    // Si está desalineado, une la mitad superior de esta palabra con la mitad inferior de la siguiente
    assign rd = half_aligned ? {RAM[word_addr + 1][15:0], RAM[word_addr][31:16]} : RAM[word_addr];
```

### **4\. Limpieza y Bloques de Ejecución (aludec.v y pipereg.v)** {#4.-limpieza-y-bloques-de-ejecución-(aludec.v-y-pipereg.v)}

Para evitar condiciones de carrera ("latches" inferidos) y asegurar un diseño combinacional y secuencial limpio, se refactorizó la lógica en varios archivos envolviendo sentencias en bloques begin ... end. Aunque esto no cambia la arquitectura a nivel macro, garantiza que la síntesis en hardware asigne las señales correctamente. Asimismo, los registros de pipeline (pipereg.v) se limpiaron para manejar el en (Stall) y clr (Flush) de una forma estructurada con prioridad, asegurando que si ocurre un Stall (en \== 0), el registro simplemente mantenga su valor.

```
always @* begin
        case(ALUOp)
            // ...
            2'b10: begin // R-type e I-type ALU
                case(funct3)
                    3'b000: begin
                        if (funct7b5 & opb5) ALUControl = 4'b0001; 
                        else                 ALUControl = 4'b0000; 
                    end
                    // ...
                endcase
            end
            // ...
        endcase
    end
```

### **5\. Monitor Universal de Pruebas (testbench.v)** {#5.-monitor-universal-de-pruebas-(testbench.v)}

Finalmente, para validar programas dinámicos que combinan instrucciones ISA y RVC, el testbench se ajustó. Ahora no busca un resultado en una dirección arbitraria sujeta a cambios por la compresión, sino que establece un "STOP UNIVERSAL": se asume que todos los algoritmos de prueba terminarán escribiendo su resultado final en la dirección de memoria 200\. Esto permite testear quicksort\_rv32c, matrix\_rv32c y tree\_rv32c sin modificar el testbench cada vez.

```
// Monitor Universal de Resultados
    always @(negedge clk) begin
        if(MemWrite) begin
            $display("RAM Write: Escribio %d en la direccion %d", WriteData, DataAdr);

            // CONDICIÓN UNIVERSAL: Termina al escribir en la dir 200
            if(DataAdr === 200) begin 
                $display("¡EXITO TOTAL! El programa ha finalizado.");
                $finish;
            end
        end
    end
```

1. ## Diagrama de el datapath final {#diagrama-de-el-datapath-final}

   `PC -> IMEM -> IF/ID -> ID/EX -> EX/MEM -> MEM/WB -> RegFile/ALU/MEM`

         `|            |         |         |          |`

         `+------------+---------+---------+----------+`

              `(stall/flush)   (forwarding)   (write-back)`

   `Fetch:  PC -> PCReg -> IMEM -> Instr`

   `Decode: Instr -> Control + RegFile + Extend -> IF/ID`

   `Execute: ID/EX -> ALU + Branch/JAL + Forwarding -> EX/MEM`

   `Memory: EX/MEM -> DMem -> MEM/WB`

   `Writeback: MEM/WB -> mux ResultSrc -> RegFile`

Datapath de referencia:

# **2\. Programa RVC : ISA**   {#2.-programa-rvc-:-isa}

## **2.1 Descripción del programa** {#2.1-descripción-del-programa}

Este programa verifica el funcionamiento de instrucciones comprimidas

## **2.2 Archivo .mem utilizado para pruebas de instrucciones** {#2.2-archivo-.mem-utilizado-para-pruebas-de-instrucciones}

La secuencia de instrucciones usada para C.ADDI  es la siguiente:

`addi x5, x0, 10`

`c.addi x5, 5`

`sw x5, 100(x0)`

Contenido del archivo `.mem`:

`00a00293`

`00010295`

`06502223`

La secuencia de instrucciones usada para C.ADD  es la siguiente:

`addi x5, x0, 10`

`addi x6, x0, 5`

`c.add x5, x6`

`sw x5, 100(x0)`

Contenido del archivo `.mem`:

`00a00293`

`00500313`

`0001929a`

`06502223`

La secuencia de instrucciones usada para C.SUB  es la siguiente:

`addi x8, x0, 20`

`addi x9, x0, 5`

`c.sub x8, x9`

`sw x8, 100(x0)`

Contenido del archivo `.mem`:

`01400413`

`00500493`

`00018c05`

`06802223`

La secuencia de instrucciones usada para C.AND  es la siguiente:

`addi x8, x0, 12`

`addi x9, x0, 10`

`c.and x8, x9`

`sw x8, 100(x0)`

Contenido del archivo `.mem`:

`00c00413`

`00a00493`

`00018c65`

`06802223`

La secuencia de instrucciones usada para C.OR  es la siguiente:

`addi x8, x0, 12`

`addi x9, x0, 10`

`c.or x8, x9`

`sw x8, 100(x0)`

Contenido del archivo `.mem`:

`00c00413`

`00a00493`

`00018c45`

`06802223`

La secuencia de instrucciones usada para C.XOR  es la siguiente:

`addi x8, x0, 12`

`addi x9, x0, 10`

`c.xor x8, x9`

`sw x8, 100(x0)`

Contenido del archivo `.mem`:

`00c00413`

`00a00493`

`00018c25`

`06802223`

La secuencia de instrucciones usada para C.SLLI  es la siguiente:

`00300293`

`0001028a`

`06502223`

Contenido del archivo `.mem`:

`00300293`

`0001028a`

`06502223`

La secuencia de instrucciones usada para C.SRLI  es la siguiente:

`addi x8, x0, 16`

`c.srli x8, 2`

`sw x8, 100(x0)`

Contenido del archivo `.mem`:

`01000413`

`00018009`

`06802223`

La secuencia de instrucciones usada para C.SRAI  es la siguiente:

`addi x8, x0, -16`

`c.srai x8, 2`

`sw x8, 100(x0)`

Contenido del archivo `.mem`:

`ff000413`

`00018409`

`06802223`

La secuencia de instrucciones usada para C.LUI  es la siguiente:

`c.lui x5, 1`

`sw x5, 100(x0)`

Contenido del archivo `.mem`:

`00016285`

`06502223`

# **3\. Validación de cada una de las instrucciones** {#3.-validación-de-cada-una-de-las-instrucciones}

## **3.1 Prueba de c.addi** {#3.1-prueba-de-c.addi}

La prueba de `C.ADDI` verifica que una instrucción comprimida de suma inmediata sea correctamente descomprimida y ejecutada como una instrucción equivalente `ADDI`. En el programa, primero se carga un valor base en un registro y luego se aplica `C.ADDI` para incrementarlo. El resultado final debe quedar disponible para la instrucción `SW`, que lo almacena en la dirección de memoria `0x64`. En el waveform se valida que `MemWrite = 1`, `DataAdr = 0x00000064` y `WriteData = 0x0000000F`, confirmando que el resultado fue `15`. 

![][image1]

## **3.2 Prueba de c.add** {#3.2-prueba-de-c.add}

La prueba de `C.ADD` verifica que una suma comprimida entre registros sea correctamente descomprimida a una operación `ADD` de 32 bits. En el programa, se cargan dos valores en registros y luego `C.ADD` suma ambos operandos. El resultado debe propagarse correctamente hasta la instrucción `SW`. En el waveform se valida que el dato almacenado sea `WriteData = 0x0000000F` en la dirección `DataAdr = 0x00000064`, confirmando que la suma produjo `15`. 

![][image2]

## **3.3 Prueba de c.sub** {#3.3-prueba-de-c.sub}

La prueba de `C.SUB` valida la ejecución de una resta comprimida entre registros del subconjunto `x8` a `x15`. En el programa, se cargan dos valores, por ejemplo `20` y `5`, y luego `C.SUB` calcula la diferencia. El resultado esperado es `15`. En el waveform se comprueba que la instrucción comprimida fue ejecutada correctamente al observar `MemWrite = 1`, `DataAdr = 0x00000064` y `WriteData = 0x0000000F`. 

![][image3]

![][image4]

## **3.4 Prueba de c.and** {#3.4-prueba-de-c.and}

La prueba de `C.AND` verifica que la operación lógica AND comprimida sea descomprimida y ejecutada correctamente. En el programa, se cargan dos valores binarios equivalentes a `12` y `10`, y luego se aplica `C.AND`. El resultado esperado es `8`, ya que `12 AND 10 = 8`. En el waveform se valida el resultado observando `WriteData = 0x00000008` cuando `MemWrite = 1` y `DataAdr = 0x00000064`. 

![][image5]

![][image6]

## **3.5 Prueba de c.or** {#3.5-prueba-de-c.or}

La prueba de `C.OR` valida la operación lógica OR comprimida. En el programa, se cargan dos valores, por ejemplo `12` y `10`, y luego se ejecuta `C.OR`. El resultado esperado es `14`, debido a que `12 OR 10 = 14`. En el waveform se confirma la correcta ejecución al observar `WriteData = 0x0000000E` en la dirección de memoria `0x00000064`. 

![][image7]

## **3.6 Prueba de c.xor** {#3.6-prueba-de-c.xor}

La prueba de `C.XOR` verifica la operación lógica XOR comprimida. En el programa, se cargan dos operandos, por ejemplo `12` y `10`, y luego se ejecuta `C.XOR`. El resultado esperado es `6`, ya que `12 XOR 10 = 6`. En el waveform se valida que el resultado se almacena correctamente cuando `MemWrite = 1`, `DataAdr = 0x00000064` y `WriteData = 0x00000006`. 

![][image8]

## **3.7 Prueba de c.slli** {#3.7-prueba-de-c.slli}

La prueba de `C.SLLI` valida el desplazamiento lógico a la izquierda usando una instrucción comprimida. En el programa, se carga un valor inicial, por ejemplo `3`, y luego se desplaza dos posiciones a la izquierda. El resultado esperado es `12`, equivalente a `3 << 2`. En el waveform se comprueba que el resultado final almacenado sea `WriteData = 0x0000000C` en la dirección `0x00000064`. 

![][image9]

![][image10]

## **3.8 Prueba de c.srli** {#3.8-prueba-de-c.srli}

La prueba de `C.SRLI` verifica el desplazamiento lógico a la derecha con una instrucción comprimida. En el programa, se carga un valor positivo, por ejemplo `16`, y se desplaza dos posiciones a la derecha. El resultado esperado es `4`, equivalente a `16 >> 2`. En el waveform se valida que el valor almacenado por la instrucción `SW` sea `WriteData = 0x00000004`. 

![][image11]

![][image12]

## **3.9 Prueba de c.srai** {#3.9-prueba-de-c.srai}

La prueba de `C.SRAI` valida el desplazamiento aritmético a la derecha mediante una instrucción comprimida. En el programa, se utiliza un valor negativo, por ejemplo `-16`, y se desplaza dos posiciones a la derecha conservando el bit de signo. El resultado esperado es `-4`, representado en complemento a dos como `0xFFFFFFFC`. En el waveform se confirma la operación al observar `WriteData = 0xFFFFFFFC` cuando `MemWrite = 1`. 

![][image13]

![][image14]

## **3.10 Prueba de c.lui** {#3.10-prueba-de-c.lui}

La prueba de `C.LUI` verifica que una carga de inmediato superior comprimida sea correctamente descomprimida y ejecutada como una instrucción `LUI`. En el programa, `C.LUI` carga el valor inmediato en la parte alta del registro destino. Para el caso probado, el resultado esperado es `0x00001000`. En el waveform se confirma la correcta ejecución cuando la instrucción `SW` almacena `WriteData = 0x00001000` en `DataAdr = 0x00000064`. 

![][image15]

![][image16]

# **4\. Algoritmos implementados** {#4.-algoritmos-implementados}

## **Matrix Multiplication**

### **16 bits:**

```
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
```

### **32 bits:**

```
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
```

## **Quicksort**

### **16 bits:**

```
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
```

### **32 bits:**

```
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
```

## **Tree Count Nodes**

### **16 bits:**

```
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
```

### **32 bits:**

```
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
```

# **5\. Comparativa de tamaño de programa** {#5.-comparativa-de-tamaño-de-programa}

## **Matrix Multiplication**

* 16 bits: 378B  
* 32 bits: 434B

Reducción del \~12.9%

## **Quicksort**

* 16 bits: 378B  
* 32 bits: 414B

Reducción del \~8.696%

## **Tree Count Nodes**

* 16 bits: 135B  
* 32 bits: 171B

Reducción del \~21.053%

# **6\. Conclusiones**  {#6.-conclusiones}

El diseño del pipeline implementado en el proyecto permite ejecutar instrucciones RISC-V en cinco etapas y manejar correctamente los riesgos principales mediante forwarding, stalling y flushing. La validación con los programas de prueba demuestra que el procesador puede ejecutar una secuencia sin dependencias y corregir las dependencias de datos y de control cuando la Hazard Unit está activa. En conjunto, el sistema cumple con el objetivo de mostrar el funcionamiento correcto del pipeline y de evidenciar cómo la unidad de riesgos mejora la ejecución del programa.

# **Bibliografía** {#bibliografía}

1. Harris, D., & Harris, S. (2020). *Digital Design and Computer Architecture: RISC-V Edition*. Morgan Kaufmann.

2. RISC-V Collaboration. (s.f.). riscv-gnu-toolchain: GNU toolchain for RISC-V, including GCC. GitHub. Recuperado el 23 de junio de 2026, de [https://github.com/riscv-collab/riscv-gnu-toolchain](https://github.com/riscv-collab/riscv-gnu-toolchain)

[image1]: <data:image/png;base64,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>

[image2]: <data:image/png;base64,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>

[image3]: <data:image/png;base64,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>

[image4]: <data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAkAAAABjCAYAAABzPb+HAAAa/klEQVR4Xu2dya70tBLHz2v1C+UdeIjbG56BDQKxug26DGKDQEKwYBkJiRWwQ4DEIIbclIekXC677O70dPL/SYHu2LErVeVyxenz+WUCAAAAANgZLz/88MOEAwcOHDhw4MCxpwMJEA4cOHDgwIFjdwcSIBw4cODAgQPH7o4X+U7M4s0335SnAAAAAACeCiRAAAAAANgdSIAAAAAAsDu6EyAAAAAAgGcHCRAAAAAAdsfjJkCnYXp5GaaTPA+uR9D5XYHdAQAA3AAkQI/OeJz18HIbXewmARqnw8thOo7yPAAAgL1w2wRonswPbjLXjjtPvA/NaRouSArG42E6YLZ3jHOCdTgM0/GABAgAAPZMdwJ00V+BUQI0hGmcPh+OocBP8KAEEqCtQQIEAAD75vESoGSVSEz67vXIfH5+gh8OVH6YhtPJnVva9RVDeTzmep2zHSUNiwwja+8QE7WWPsZZ5NjOyzQMeSJyOtKKxNoG3YdspZQARRmXNpnunDqKK25i8hc616jKyewS+0jt0UDN7gupPp0cmc7bODcB8rpNbX8YjsJm28kJAADgOjxeArSgT/p+oqTEZ1wmTfo/r3scKGlJrnKvPvIExYJkoIl9nixFg019UGIw3+MYTtGkyCdC+u7ug+Fe0WTJQ0EXk0+C5OR6GkICFNDq6Gh2aJQz2MV/HucEI5WhnfK9Sn1SotF2XznnJkCkW0r0TqsQiy8vZzaUEwAAwHW4bQLESRIgjcJEqCZOrG5x1YMmrlp/GhUZZNtqH3MiwFYC0pUCWkWQKweefHIuyDHpyc22CVCjnMKeUoZ2yvcq9UkrK5pcLeQ6bqN0X5Qkru1tJycAAIDr0J0AbcY1E6DChN1PXYbePtxrkWX2bEwsHAU5Jj25kZO0Vkfn0ROglHEcmT77yHXcRum+SueJS+QEAABwHV5fAkTf6FXTkP6Whl7ZbLYCNLX1QZPi4bjWOYlEpOnVkqMsx/K6xX0Z/W91XpQEaDlBdWh1YlCSGi0BapTzBgmQ1CfdS1til3NJAmS9AttSTgAAANfh9gmQ+vponfDotyPZa6X4ain+2DZ8H91k+TL/1/+f/7g3JgL66ycL/xuWTAYxMVt9uCRgWOvIhMnVSdrIkypVjiSRS2Wl6480Sb9w09IqjpCTdWL3YcjJ7ELnXJIQ+2qc+FUZhBxSn7G/LrgPdcpI+MSu9mpzIzkBAABcldsnQAA8MeevbAEAAHgkkAAB0AESIAAAeB10J0Cb/RUYAAAAAMCdQAIEAAAAgN2BBAgAAAAAu6M7AQIAAAAAeHaQAAEAAABgdyABAgAAAMDuQAIEAAAAgN2BBAgAAAAAu6M7AcJfgQEA7oLbxkTfJw6AuwP/fDqQAIHXS9z3a/N/uvnkNlP1e5UNhU1V0zo5bW1Y5fU2rPLIONGGt1VdBV2Wim8CJpiAZVernHgm/2R7GZ65ibHjavEgcE3/TPbQvKSPuGG2pse4pyY/Lunr8blLAjSKjTWH+btzSnWjVN0Q4+m4DIpkM0pls0tfh11dqCM3AK3BN/zMjtAX7cIuy+LGm+v1hY1ggyy8HzlutfY3H9wFm8gNQFtwu9Lno64ZqfOmWyVbN1VshTZClZufyiCh1GGf1fJCG5FSebkNq3w564Ke29y2ZBrnA7PtDo06DySb9Dq7i417L/AFyUW+9UA+bmPZ1SonlDrss1peaCNSKi+3YZWv0Lg/HLWSM9g8HtwaGq+6nizG+d4PlGjSZs5qInl+28/K7RMgMgJ3wDFk9zEBimX0eUlIhGFcAnNwhvRfDy5hWOyZXEvffeBNAtMokh15TQPqvlDqAPPyS5YJXSZn4nq6v+OxIp9yzbbkA8MlX1znDWw1OZj64PToppQYh8M1Q/4r7iG7L6WOVW61YZUTSR2rPOAnl5pN1rGj+nsNPqbimKWuzhhrFtq99fEAPl7xv0Xvll2tckKpY5VbbVjlRLecgW6/q0E63qyxe5D7qT/d4DsMJECe7gToUpagwpUfnbIpARrnz7nxkkGiBVjp+CEBWgaddo0B73NxKNmPo5wADScqY/ejXB/l0p12Uq+RxGRLCzA2+sCQOh/4cnZITmOZ9oS9TIjyeq2NCLMT6UMUzk+VaRu03Mt14/xvLjvFxDvWU7rSUIO00L9Wxyo327DKCVbHKg8nVLtynL7CNf0TkW/fD4vZ92Z7ueuFnN5eZIOCTRL/EfK2+JaDte1WnaXBdV0s92z5Z0GOpBurjQYsu1rlhFbHKjfbsMqJTjndd6HP7BoTFhOUeJD6he4bbuWEyzDQd+YrJf+M8s/9+j7I/9f+0oWASvxM0P20F30uobbrunht3DwBItwrsCQYnfxTVksCVEpU+OCRdVxgDcF3OXdcHfpMI6evZDSHitQSIB8MlidNGQRmlq9KWfU84xoJUBrExjWppcFs1pew691XvY1kEj5xnYZl3WRSCsEm081pcr8lKAaZMuo9NAR/q9xswyoneieYOE5YgE+ucAF8tUF/AkQ2oeuDbeLkQ/0lsoXAa9pE90NCvV/GkV6vJK4xiOCut7222+afdTna2qihtt9pd62OVW62YZUTnXKup3v9LiJighIPpF8Q0jfc6+GknBIezW6KD7nkiOaeMXyme/Gf07p2/PQofZyBngDl0Gr7ebp/Dm6eAKmKlwlL6ZyjfwXoRINNLmWPWtt9tA/MegLkCANlmSSW0/nvfFoCB7W9HfqgW+Wncj556fXVoBdIryfyNqq6IP1pxlB0Q23LM80o7WX3pdSxyq02rHIiqWOVO4Ld2KlBHXOedn9fcdcMqyw0/vPfEuW21inXy++NEeJBoTSgtx3vucU/ibIccozEc3kbVSy7WuWEUscqt9qwyoluOQPn+J1Diwm83ya/mLK5poxiz2Qu4uXysx0/PbWydtR5WEOx02tiy1myCfcjSHI6pnzV8YsJ0OSNwhzG/A2QO7Uu5YcT6+dAs1ME2gemd1qJvH6Z4JeTc7J3kNed3CSViKk4qUyAtl4Bck9BUQ6XvA3+SWqMf1GUD1JnZ3ZvlJhSPbpsud4VaW14Xcg2V130rQDJM+2EVY1FVupDypXXscpLbVjl5Tas8nA6sYl/2i0h/bWF6NPrnEPf5TjL/UunXK/mWwT5E783espP/+ghb5v7uO2foUjIscjAx4j7Xm6jjmVXq1yvY5WX2rDKy21Y5Svn+J3HXgGKfsHdUfqGTJL8H+BIHyZyH2pKgIRv1P1C6eMMtLnO62Kdm/1K17m6fw66E6BLfwQdl8LTd6pMw84Z0qd8zRnSvwJjDuySo/XatWkaDL6t/4o665E7RYmYUCyHkqwtCQ07YgKSXM8mcfcqgIRmeljuIZH7ML3xRt4+PzhnJ0CqPUjnIigsNqUlU1rC9Z+ziY69b08Gm/zLQNbGf/6XypDrI/Yz6r8Bcp/JPtEH+JH7lkkMpLEPTaWiTkZjG1Z5tQ2rPLD8CfyLeAUWET7QExD9GGA6jg8voaPcHnSkNlHrZOOt7FtLjegLsTwWNPh4zT9rPp4+6LW2YWDZ1SonnsA/tfjZ43seFhOyeODxfxa+9lGObaFcyKr653wk8drFeEpe6Dv5d/zsbc/70Pyi1Ec+DioU5r2kSuaj0mivi5snQAAAAAAA9wYJEAAAAAB2BxIgAAAAAOyO7gQIAAAAAODZQQIEAAAAgN2BBAgAAAAAuwMJEAAAAAB2BxIgAAAAAOyO7gQIfwUGAAAAgGcHCRAAAAAAdgcSIAAAAADsjjsmQLQXSrrnTzdubxNlH5tWwvUXyQCeEth9n+zR7rSPVP8eWo/JQ9/HjeeT12TXe9GdAF1M2B132SQw7oSbVPKbdx6O8uzjoO5gf1eshNIq70TZgf5SttDpFm08B2RPttP1RHtLHtkmjRvb+4HJNibmR7ePXlNvYbPjF79DfNycWfZFG2PyzSi1nbtbkZOktgnzstFmz8aad4Dk1NA3Cj1fZyZXiH29SLvSPCp1IDd1vS3XHEcKZ9pE96hr0igoDdSGanfj8SZay+Gs8k4a7djDFjrdoo2nQNP/HASH5d43tveDo8YLTUcm19Wbm6xDouGSkZCERCj54e7rdy8/czKn+1eSGk1X/Xq6MYV7Sbmu7RbO8qsNKehC3jvFQulft+NGtoicaZPbJ0CzOY7DPKCPp2lcloEYbhlRZvO0GsTqulWjWCZegcXrD4PrZ82G88kiXq+rbZybWq93T2PDOrn6ifaUPH1kfTQwzvKu90Jt0HcmE8/s6Z7YE3+K5XC18rmM3cc6iUa8zbgcLjD33C9Nzoe0DX4vXAdc55koJRKfqLSx1BO6YH7jdUFP36teVtumunL1moVMiU/j5yVsYgVoPHkbLYGRyi+Qs3UcJeMkHSM9XKYLf30UbVkx4UGxZPeM0jjZxu7uPoNMboJK9El95BObtgLUoq9slSBgJ0D12Ofh+sh14e4t6ntkdSl2uKotfayU7iVFtx3FqkMY0+S/aTiw5Jzs2Cfmo1JcKY4jpU4+zlZKulDvXdh61cWqj1gvl5/FEKrXJaduC0KTIbG6MVe0zUdtcekOCVBgTn5OJ3+jmQKm3HA6XskZziHZoBxpGVlrr2wkZ2z+qi4olCdAfpK0+ijjkig5IE/ylSArJccoyVu7F0e5/Disg52gpGwNaGEJPq3gA0XPzc7tJPmuci9brN60tiH7dkS/oXsNQS1+jvWlrtxlib7aaZnEqvDkmYIA+Y4ygUbIf/tM1jCOkqfRdIz0cKkuklc7lBgWmlHtnqCPky3tXoT03WggU18xfsnzkx5bk7FsxD5C6kPXRZhAZfxwRXYfC5V7Sclt531+vdI9cMqbr8lJ8a859uX9O1rGEa+jlUcqutD65vFQ6sKVn9b5M3lwcLHP1UjbbZWzpIuJfseVy5DaRJ8rYlnTfJT4V8G3qE56xma7H0GvaANSO5dTSYDERKC3VzaSUzTPMl2mujqeNtHqfZTRnuwyRvlutyRv7V6IQnny9MKOqL9SUCbn0c6XICdesn79XjSd9tLaRlEXyQpKrLN+VnXF9XVPkmRE4Qyb2eOIj5N0jNwSLldtXKl2T9DHyU3sXhprZ1CemDQb5itAtdhnxowFXZceow+Gfi9iYnbI/mhizNvM/UNexxjlPU2VcVRop2UciTpZeUDXhUfre42Hui6IJS87+gckdw2twPgvqU82ylnUxZQvdhCJTQpzRSxTx0hmEzsuubc34pzJpQkQKSydoPQssqxYzjUToBR6XeeW1EIj2kSr91EmH4gSku8gvpfkrZURhfKgq6IYzQ5Xw99H+nSVy6PptJfWNmTfjpYEqKarO5OPLUGXzaaOceSRY+SW1OTiqHZPyP2SuI3d9b67qawSEJquajbL7GrFjIX2+8n6iBTvRWtbnjupk34ed+V1jEdKgIq68Gh9r+3ouiAWXdBKzDGssNCqytzeUcbTFjkdBV1MVgJUniscZ8xHqm8FXd4lAaKlRp75yyWxWK9wPwymGE6Lw/mzBSP5+vQbn1WyWYnMGbSJVu+jjM+0U6ekV2D0WtA1TfexGD6+09Tlrd2Lp1zulgeH9V5pSZK/1mhacqwR7mNponAv8ZVg+Ob0Hf9ippXWNlRdNCRAUldEqq923Fh4MZKWCnyZ2OmT+ZKX87jU8a9W+/yzZRzFceJJx0gPl+pCylVCtXuCPk62tHsVmoRYm85u2YRd15epC9cHG4/zXWk2XVvO7Rr1sdRQdaHrkmjpgyjfi39w5jZxY13EU/naJ3/dQpTldP00x75COw3jSNbJygvnOLJv7ztpTJBzLX8F5uQ/rHOS9zHhew1yegq6mIxXYJW5Ipxomo9S/8p9K8p98wRoQXEKf5onR+vBlcx/eLwcsS0aiOzcasg0YFTbCNcM7gfJ7Now2BIZg2BaHy3QX30kfSSByZf7MnJeehfqP8cu1PugI9yLVR5xP0yLMmTLhWK5Ov7oTGmnRHqf+r34AbjKyCfwduptqPqge8j8hgYwfadBHD/71TiuK11fbdQmMZPkB5v0Tj4PNamcefCrkulD9/E4TlZd6E94FpfogssV5ZUU7V4rF3W2srsFTVxLHyIeRIr6alydSf/4gq8y12NfUm+JTVIXPjnJdMkmxKY+zHuJk2Noo6SrxW4yibXlJKzYp7cRptaWcSTqZOWEpYtR/lRC2sQjY4JMBl1SGft0crGHxwY5S7oojyNpk/Jcsbq6PR9J/5J9RF12J0CbUUiAAAAAnEd8sn0NvKZ7uRToYluiLu+XAAEAAAAA3AkkQAAAAADYHUiAAAAAALA7kAABAAAAYHd0J0Cb/RUYAAAAAMCdQAIEAAAAgN2BBAgAAAAAu6M7AQIAAAAAeHaaE6Bffvll+vjjj6dPPvlk+vXXX2UxAAAAAMDT0JQAffvtt9Pbb789ff3119NXX33lPn/33XeyGrgn4Z8tf/h/LPRZ5AQAAPCqqSZAf//99/T5559P77333vTjjz8u57///vvp3Xffnb788svp33//ZVfcCLdhWtwrRNkM9QGI+4Vle/Vci2dJLB5JzrDxXp+F4m7J8jwoc3I6i/v25LqzyltoaeNklFvYffjNjNd9jB4SET8fYiy2QLHjLvtB2HZvq2MR2ihev2EfpTbEHnF3UfcNqSZAH3zwwfThhx9Of/zxhyyafvvtN1f+0UcfTX/++acsvhF+x9lHRdsx/lWSBFR+PHZwpf11zrLP3QLxM0IbF6abMp4G7hdWeQstbfg6kbzcoqEP8gu2ISclQ+e41+0o79j9qNxj3Jl2L/hGH2kbrX30aUNvg32b/SHdaZ18WNtg9lrEzVRlXHYLClfYO7SaAH3xxRfTP//8I08v0ArRZ599Nr3//vuy6EYgAXoIKAEKgWnd4PbBg2tY/TlPvtEHitdsWr7zs3I0z0P0RKkEM77jdLW8hZY2RJ2s3KKlD4VmPd2FBx+jCl0JUMWHe5qRNs7sXvCNLiz/LPQhz1UptLGgPdjNcXLo6eNiyCf9wzPThkuMOkzWTDUB+vnnn10C9Ndff6kHlVGdd955R15aJL4acqsD42ldLj7ERIadc8ehYoBCAkRGi8t8oe0kqw0yxLpx9WKxfRw4dN2wthMn+ciYLBdSOX1fA4p3UFpy1K9vY0x1MQinryxnx3vw+qTlzFW3miy0IrLopYeWBKgip9N3k5y5b5yL8wFFB6TvE7O5qvPJ60qek0R9WvVKkH9pvhX9ievJ11mf7pJ+NR+/EWqQZoHWKk9P6/psaSOrc4U+Mub4Ji9pxdm01naRfIxY8TPrxYif3P803/NY46hFTlqxSOU4TyeXYdm95BuSkm8RWRuNfUh9dPVBJHKKFSDyX9L/FVZeynifHAYxHyerXRXfYXP3Mp8oc8npOMdTOr+cUaDk5ptvvpneeust9aCy3gTIE7I8+i2FWF870o0KG9FEkA8OopAAzQNn5NVpQIuBnmS+k3ecxJfcpMEUO/osNNZxzjR/Sbo5pasKPtGiCd3X4tc3M9/7ei8+qGRO7FCCWbwH6j9MgvFzVndaB083LQnQgn6+RU7NN3S/sCkmMC4ZO5o6d7Y1AkMtGFlE/1q+C99ybbvXLaxt0h3J7j7mMmc+fgM0OXjgtsrT07o+W9rI6lyhj+R8CMzn4q7X2jbQxogVP/Ne7PgZ/W+B+V6oUB1Htpzht3a80jwhn6OTS7HsXvINScm3iKyNxj6kPrr6IKScJ/ZQT/GF4o4R57Yl+GTwJ8L/5vJUnQcS3xHznjaXxDm5OttRckM/cqZXXdpBZecnQMrAC5PfmtmxQzVCIQGim00yRDrS/poSINEnr9PyQ1jpcFkfTaQrQPmTVkTRaXIPvFypuxFSZzl636acJd8w+9OhZDQLBg7x1FnQeUsCdAmWf5V8iSYZuk76ni/Tr1FZJnH9aG1Hk4MHbqu8hZY2sjpX6CPjghWgc1HHSHGc6GOxJX5qvhR9z1MfR6ac7KGKU9W3pOLDPc1Ydi/5Rg9ZG4199Oij1EYV6kP1nWux+qSLgcc4h4UEqDQPSN9h84nXUDqvRC2YCZDF5gkQPTXI80W0BIjOyZWlvL/nSYBWxjEsK6uN5PcoHUFNLDZG6ixH79uUs9s36pAtsmCgUNL54yZA/rz0PV52U5QgnchmlbfQ0kbLhFKjpQ8Fec216Rsj2lhsi5+aL2nnInIcmXJukQBthOwzs3vBN7qw/LPQh+V/CYU2arTGye1gvhYSWC8yS4BafOcpE6CJ7pmeFOSrpVIWqiRALkMc1iWyOPBkf6f4I6vRvw+UTwVGAuScTxjC/wnsOnFJB60FiBJ0zdoCyVpyekWnnQkQ9UUOdwlSZzl63y1yar6h+4WNS2AUY/gBz/vQdd4SGKI+rXoa0b+W78K3XNuVV2AueCz+WfDxm0CvMvh4nG1K35vLV8r6bGnD1ymXey7pw/kE98+5Tt5OC37V9xxbaWPEip9ZzGiIn9H/FsTEZI0jW87HeQVm2b3kG5KybxGsjY4+pDaa+3Bfczl5OHF2t5KNAqscUkILxSfD+XjO9B0zAWp8BfbTTz/JUxlUh/5NoDb872iypSs5uEKwjuXyFYTaBp8skuvpXSC9//OfV79YXy2RMo/ccULmGdulS6JB6dD7ma9lzuUm2FgWBu1ST3VOHRdIeB/C8Kou6Jjl5p9H5wD0nXQdP6erDBclQNnSZGrTmpyLvhvklL7RrklBDPTiNOlgcD84XvuQOiffafkrsHowsiH/WmTggWsKcp7S1wzpOEnHWubjt8QF2mjv9D6aygNVfba0QRNorXy6vI/UP+tP10Vm37xkopdj5BrxM/pfqY+WcWTJ6XyYv0Y7rHHipjTYvaVO1beI2Ebh+k370NpIyuj3rxf44DkJkJhD4j2sc2l5Hlh8J5u7acznc8ly/dK5wqeffur+1Wf54+d4UBnV+f333+WlADw+IQkqhIoC4cm076LN8ROQPAteA5SgPDrwP/Aa6B5p2A0egPuSPsHfPxkD+4L7H3wPPDNIgO5B9rpIOzCxAQAAANcCCRAAAAAAdgcSIAAAAADsju4ECAAAAADg2UECBAAAAIDdgQQIAAAAALsDCRAAAAAAdgcSIAAAAADsju4ECH8FBgAAAIBnBwkQAAAAAHYHEiAAAAAA7A4kQAAAAADYHd0JEAAAAADAs4MECAAAAAC7AwkQAAAAAHYHEiAAAAAA7I7uBAg/ggYAAADAs4MECAAAAAC7AwkQAAAAAHbH/wGzhdbYlb70qwAAAABJRU5ErkJggg==>

[image5]: <data:image/png;base64,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>

[image6]: <data:image/png;base64,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>

[image7]: <data:image/png;base64,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>

[image8]: <data:image/png;base64,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>

[image9]: <data:image/png;base64,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>

[image10]: <data:image/png;base64,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>

[image11]: <data:image/png;base64,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>

[image12]: <data:image/png;base64,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>

[image13]: <data:image/png;base64,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>

[image14]: <data:image/png;base64,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>

[image15]: <data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAkAAAABzCAYAAABw670cAAAUSElEQVR4Xu2dT+wcR1bHx5KlVZwIraOVOMByySUSN2Qj/zhySYJiBOJoMKcfYiH+owUZCRJE7M1lhew9JUpQYI2U4OUSLj+JXaEcIkW7CxKS95CDubAsazt2NixZBBJCKqa6p3revK6emZ6a7tf1q0+1Punu1/Xn9auZmm866febPXjwwAEAAACUxGxe/D9gJHzRNgAAAOjP/Bd1Z2a6MxgWX7QNAAAA+iPEzMpe09Gm3SEMBwIIAABgP2gB1EVHm3aHMBwIIAAAgP2ghU4fZrozGBZftA0AAAD6k1JmujMYlkXQAQAAIJHFk5xdaRlgQBBAAAAA+wEBlBEIIAAAgP2AAMoIBBAAAMB+QABlBAIIAABgPyQJoJ/85L9cjoSi7VPm/fffRwABAADsiSQB9Nlnn7kcCUXbpwwCCAAAYH8kCaAf//g/XY6Eou1TBgEEAACwP5IE0Kef/ofLkVC0fcoggAAAAPZHkgD60SefusAnj//Wnf3KP1XHs9lvN/YpEoq2B2azs4v98j78/X3j8Y9adccCAQQAALA/kgTQ48efuMCjR9+ojP54NrvoHt35SnN+4+JZd+fRY+eFhT8/O7dfvPOPTduxCUXbAzfOzqr7+e7c57Pz49nZi9W5vwfPxcV9jXkfCCAAAID9kSSAHn382AU+fnjH3fj2I+dFjhdAHz/8biUQvO07D739YiUcPn73YtOBbD8moWh7wPvuffXH33n3RuWrv7+/md+Hx+I+xhZAXWPJsqnurmzqXxZt033twrb96DG3bbcNsmi7Pte2FGRfsX5j48VsKci+Yv3Ksq7ernT1pccLRddLIfQX61vbZNH97Eroq6vP2Hj6fFfWjS1toeg6qWwaX9r1+b7RfcuibbrtLmzbjx5z23bbIIu263Nt2xVX/WHT9fcTG686f/DgYxe4f/9d9+qHD6vj2ew33TsXzrgLr37bXXjnofvw/kM3O3PdXZg39NfPzPdnLlxv2o5NKNou8X77vb/ZD189U93fO/4+5ucW9zG2AOpCFmnbpt42hPqyne5DFm2L1Yv1sQ9k/+G8q07sWhehbqxd7FzbdL3Y9Rih3rq2ofSx6WubkPVjbWXpW28buupLuyy6XlebTcj+5HHsujyXNl1PX+siVj/WNhRt0+ey6D7W0dVG2rrq6Pqb6qxDt9X96fNYu9j1GLG+Yue6nj7XNn1tHbLdOnS9WBtZ9LVNxNrFzrVN14tdj+EWT4DWtQ1F22b3f/jQ5Ugo2j5lxhZAsbGCLZRYPV1HX9+Ebifbb7JJu7bpa+vY1E5e66qn6+jr65D19X6TTZ/LosfR6LqyjbTp69Km+9L9bGJTO2nrqiftoeh+upB1w/G2Nn0uix6nC922j032Ia/rMWLIottta4v1Fbvehawbaxdssl9dT9fR19eh226y6eOu+puQbXSfm2zSrm362jo2tZPXuurpOvr6OmTdcLytTZ/LosfROCWAZBtp09er/b//4L7LkVC0fcqMLYCsKOEepwqxLxfm3g5ib0cQQDvxb9//ocuRULR9yiCAYGiIfbkw93YQezuSBND3//UHLkdC0fYps28BRF/9oK9+0Nfw7HN8+uoHffVjun21bT1oGbIgFG2fOjn63Bcv9LQNxoHYlwtzbwextwMBlBGNz0NvkbFHw3rT/oyN9ab9GRPrTfszNtab9mdMrDftz5hYb9qfsTHcBhNA524/5574maeqvb5mTfYC6M6c8wNxY9Yad1T8pn0aE+3P2Gh/xiRtMUhnyM/1Jqw/9x7t05gw93aw5pkxuADy6GuHR/6H/KBlH4uYADrw9qPDVt0pgQAaAe3P2Gh/xiRtMUhnyM/1Jqw/9x7t05gw93aw5pkxqAB67oUD90e/e76xzRWGmx3cagRQvW+3HZqWAJo74ve37tn4sy0IoBHQ/oyN9mdM0haDdIb8XG/C+nPv0T6NCXNvB2ueGYMKoP9544vuf/9++VTlMOwXAujWQbvdGHQJoCNpmyAIoBHQ/oyN9mdM0haDdIb8XG/C+nPv0T6NCXNvB2ueGYMJIM8v/sLPu8u/9SvNuRc+zt1b+U9gR4ftdkPTEkALm643NRBAI6D9GRvtz5ikLQbpDPm53oT1596jfRoT5t4O1jwzBhVAUyUmgHIAATQC2p+x0f6MSdpikM6Qn+tNWH/uPdqnMWHu7WDNMwMBlBEIoBHQ/oyN9mdM0haDdIb8XG/C+nPv0T6NCXNvB2ueGQigjMjR576QFMwOYl8uzL0dxN4OBFBGND6zsckt8lnZBRbicmHu7SD2diCAMqLx2fJx8cC89r3XWjZYQ9oXeAUW4nJh7u0g9nYMJoDWJUK0JiaAfPHJEHXdKYEAghZpX+AVWIjLhbm3g9jbMaoAOjo8rHIB+eJzAIX9gc9AuHg9vvmRH5BQGtvBrWpPHiB7EEA9SfsCr8BCXC7MvR3E3o5BBZBPhPh///J3ja3K+RNUjhAh8niMpzByvAoyQU8GBFBP0r7AK7AQlwtzbwext2MwAfS5Lzzhvnn9l9x/v/FzjS0kPfRPgW4dLZ66HHonvACpEyOGbNFD0hJAs1p43btl9/fJtgEBBC3SvsArsBCXC3NvB7G3YzABNGViAigHEEDQIu0LvAILcbkw93YQezsQQBmBAIIWaV/gFViIy4W5t4PY24EAyogcfe4Li4EdxL5cmHs7iL0dCKCMyNHnvrAY2EHsy4W5t4PY24EAyogcfQYAAJgcbg8C6MSJE9rovnTpqrvy8vXqOOynBAIIAABgAqSJkCSSBZDn5s2bKxdeuvaKe/ODj9zlL1+r9sHukx76pIPV6/CL5IMNi1w8AZ8csT5Wr6arehKfYqjazw4bW5XcMCQ6XLyG3xZAdf17822ZDLFt8/6HvqUt3I+0LfveHwgggN3R33t9HrPJom26fwDoSUSAbPquSZvch2N5Lm0xXGT8HixPTp061Rx7AfTG27fdpctX3ddef6ux+3w/R5WgqEVFSDxY5d8JyQgr8XAgBJAQFL6OFEArYuhQJFFcCqB551V//rhTAIlEiHX9uK3OE1T3LW31uAeqXvBlf2yaTADoRn/v9XnMJou26f4BIJ1N3zVpk/twLM+lLUayADp9+rR7+umn9YWKr371z1dtB7cWYuaw2scEUEiKGASQ1x9+7+tXx0IohWvV+byP2NMb/1QojNMpgGbLRIj1U6RawMRsoW9p88LHj7Fab/9onwGgH+E7JL9Lu9ikHQB2pEOAxL5rXTZZZD19HMN1jL8lLYMJm26yYq5O1gmgHMjRZwAAgE7SREgSx0IA9QUBBAAAUDD7eAssRxBA04WcGHYQ+3Jh7u0g9nYggDIiR5/7wmJgB7EvF+beDmJvBwIoI3L0GQAAuilWAKWJj72AAMqIHH0GAIAO3EIApf0Qwy7s6/8B2jYRojuqXyEPr6U39pB7RxCSGuq2Mar8Qos3vFaSFqo+lvW1AGonPYzZQj4ibZO+uaPuRI2pIIBgH+jPvyzb2HR/AMmk/RCtJfa5lTa5D8ex86EY4gmQLNoWq6fPtU33vzci867H1uNrmyyx9rr/1b7ath4sT7ZKhNgIhaVg8Ll2pADSYsgnTQxtV4XT4Urd5hV3kYxwawEUSXoYs4UEh9rmj33eonq8bqGWyqbJBNgG/fmXZRub7g9gysQ+t9Im9+E4dj4YaT/CUWTRtlg9fa5tuv8h0WPr8bVNFn0ebF24tNjP3MmTJ92VK1f0Bffii+fd3bt33fPPv9DYggCqnp4s/jxFI4AW5yGpYDj2T1tCW/3kyHO42C+fANX1vX1rAdQ87akzVXfZwljaVo+9mihxCDZNJsA26M+/LNvYdH8AyaT9EK0l9rmVNrkPx7HzoeAJ0Cp6bD2+tsmi+5C2GC4yfg9ahkmxvQDKgxx9BgBYS9qPUPYMIYCywnD+j7UA6gIBBAAA5jj+J2gzHAIoKxqf2djY2I7LFta4EreZeAJU4mY599Vvar3fkZYhC7IXQMeY4h8HG0Lsy4W5t4PY24EAyogcfe4Li4EdxL5cmHs7io/9HTsGEUA/+2vPuHO3n3NPPfP5aq+vW4MAmi7FLwaGEPtyYe7tKD725+0YRAB5ggDyBJv8AV+X2DAQXnvXr7/rXEF9iQkgfT5FcvAxleIXA0OIfbkw93YUH/uIMBmLQQXQ7/z+77lvfutbjc0nDfR5f/zr6V4AVUImJBz0GZWrH/iQT2dZX+cACgKouub6Z14OZdW+WZBZ0/b5+FH8YmAIsS8X5t6O4mMfESZjMagA8okQ/+APrzU2L2h8EsHw5yNCYsFASC7ohU3Iuuzr+fOWAFoIp11AAE2X4hcDQ4h9uTD3dhQf+4gwGYvBBJDn3Llz7o//5OXmvBY1tdCoBJB/EiR+1KUACoInJDOUAqjJFO28Flo+MdqWUFbtCKApUPxiYAixLxfm3o7iYx8RJmMxqACaKnEBNH1y9LkvxS8GhhD7cmHu7Sg+9hFhMhYIoIxofGZjY2NjYzsO2w07EEAZkaPPfSn+34YMIfblwtzbQeztQABlROMzG9tx28LnvNSt5PsP6xvAiNS/qcvP3w60DFmQvQACgONH2mIMAD1wnrTv3MydPn3aPfnkkysXXrr2invzg4+q47D3bJP8UBd9veHwaN5dXT+8CSbfFKveMOt4Xb7Vd1PnsDlevKDWOvb34MeNHes+9v1m2YrPAMeJtIUIcoa5ByOSBZDn4GD1VXQvgF7/h3927733XrUP9pDQsBET8xJeha/tRyv5f6p2CzFR1TmYj7XoQAqb8Kq878rvfb06x1BcgISyajtqxpTJFWWuouZ4PmAYUx7rPrYRfH3QPkN/ZAxl0TZZV9q6+oI9kLYYdRKbv21tozHAvW9zP7E6XTbddp+4iK1k9BzIso1N96X7hxqX9r2rD5599tmVC7/667/hvv71v3aXLl91b771F41dZnT2IiU8PZF5f1oC6KB+ihOKFCGhXy+J/D4IoNCnzCotCUXa/Pihb/kk6d69OjfR6vGBW4qk5bHuQyd6TEX7DP2RMZRF23TdWB9d12FayDnta8sZfT/heJ0tdk0fw7jEYr/JFo5j9WCJSxVAJ06c0MZOtACSk9QSQIvStHX1f+qqtdC9lSdDoc3KEyB/0vEEJpRw3jzNmdXJGUNfQdjIY99nEDb6WPfR9QRqV6TPAMeKtIUIcoa5ByOSBVCOhKLtUydHnwFgS9IWYwDogfOkfedahixAAAFMlLQFKU9KvGeACYAAyogcfe4LScHsIPblwtzbQeztQABlRI4+94XFwA5iXy7MvR3E3g4EUEY0Pt+Ztf6o23Hhte+91rLBOBB7Q/zfJop858eCH2E7iL0dgwigz33hCXfu9nPuqWc+7376l7/Yum4NAmi68CNsB7E3BAFULMTejkEEkCcIIE+wydfSfUJD3WbfVK+pN6+kC3tLANV+3fOv10f6mQoIIBgSYm8IAqhYiL0dgwqgu3fvulf+9M8am8wDtEwkuMyw7PP31Dl9akHikxk2f+ZikTgxlHBc97Xc+3JP5uzZRgAtcgrJBIhTpPEZAQQDQOwNQQAVC7G3YzAB9FPPPu3e/su/qkRQsHlB4oVLLTRqkVMLGS9AaqGjBVD9o7+sGwRNnel5mU26ujbf3zq6tfzTFNsKoEV/QWxNFQQQDAmxNwQBVCzE3o7BBNC+GEKUxARQDiCAYEiIvSEIoGIh9nZMXgANAQJouvAjbAexNwQBVCzE3g4EUEbk6HNfWAzsIPblwtzbQeztQABlRI4+94XFwA5iXy7MvR3E3g4EUEbk6DMAAHRTrABKEx97IVkAnThxQhvdly5ddVdevl4dh/2UQAABAMAUKFYABdJESBLJAshz8+bNlQsvXXvFvfnBR+7yl69V+2APiRDDK+xd+De/5v9ws4Nb9fkiQaHfy2SK1fHhkTtqhEF9bVNCw7YAWraL9RVsPhdRzFa9ij/3VdfbNwggOC60v4NtmyzapvsDyJUhBJAs2qbr6XNdT9fZKxEBosfW42ubLOtsMVxk/B4sT06dOtUcewH0xtu33aXLV93XXn+rsVfFC5tZLRJ8PqCQtPBoIVp8Lp9GAC3Oq7ohEeJCAMkba0TLlgkNW4ER7cK4MVuTlFHZakG39HmIV/c9Kz4DZEzrOxixyaJtuj+AbEn7EY4ii7bputu00/WGRI+tx9c2WdbZYri02M/cyZMn3ZUrV/QF9+KL56skiM8//0Jjq8XLMrNzsHtB0SWA3L1FVmeR3bnprxFP4SbDU5tllukY7cAs2wU/YraQsVrbqnupngCt1ts3myYTIBfa38G2TRZt0/0B5IrlEyCNLNKm6+2NiADRY+vxtU2WdbYYLjJ+D1qGwZECaFe2CcwUydFnAADoZggBlBVpIiSJ7ATQPkAAAQCAOW4hgNJ+iGEXHAIoKxqf2djY2Njy32biCVCJW/h9s9iq39R6vyMtQxZkL4COMcU/DjaE2JcLc28HsbcDAZQROfrcFxYDO4h9uTD3dhB7OxBAGZGjz31hMbCD2JcLc28HsbcDAZQROfrcFxYDO4h9uTD3dhB7OxBAGZGjz31hMbCD2JcLc28HsbcDAZQROfrcFxYDO4h9uTD3dhB7OxBAGZGjz31hMbCD2JcLc28HsbcDAZQROfrcFxYDO4h9uTD3dhB7OxBAGZGjz31hMbCD2JcLc28HsbcDAZQROfrcFxYDO4h9uTD3dhB7OxBAGZGjz31hMbCD2JcLc28HsbcDAZQROfrcFxYDO4h9uTD3dhB7OxBAGZGjz31hMbCD2JcLc28HsbcDAZQROfrcFxYDO4h9uTD3dhB7OxBAGZGjz31hMbCD2JcLc28HsbcDAZQROfrcFxYDO4h9uTD3dhB7OxBAGZGjz31hMbCD2JcLc28HsbcDAZQROfrcFxYDO4h9uTD3dhB7O1IE0P8DzuFcH73RIqoAAAAASUVORK5CYII=>

[image16]: <data:image/png;base64,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>