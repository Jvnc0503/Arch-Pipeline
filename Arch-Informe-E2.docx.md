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

[1.2 Cambios del Código	4](#1.2-cambios-del-código)

[1.2.1 El Módulo Descompresor (decompressor.v)	4](#1.2.1-el-módulo-descompresor-\(decompressor.v\))

[1.2.2 Adaptación del Datapath y Control del PC (datapath.v)	5](#1.2.2-adaptación-del-datapath-y-control-del-pc-\(datapath.v\))

[1.2.3 Fetch Desalineado en la Memoria de Instrucciones (imem.v)	6](#1.2.3-fetch-desalineado-en-la-memoria-de-instrucciones-\(imem.v\))

[1.2.4 Limpieza y Bloques de Ejecución (aludec.v y pipereg.v)	6](#1.2.4-limpieza-y-bloques-de-ejecución-\(aludec.v-y-pipereg.v\))

[1.2.5 Monitor Universal de Pruebas (testbench.v)	7](#1.2.5-monitor-universal-de-pruebas-\(testbench.v\))

[1.3 Explicación de las Instrucciones	7](#1.3-explicación-de-las-instrucciones)

[c.addi	7](#c.addi)

[c.add	8](#c.add)

[c.sub	8](#c.sub,-c.xor,-c.or,-c.and)

[e c.and	8](#heading=h.tbhh1woysind)

[c.or	8](#heading=h.9kigebduywc1)

[c.xor	8](#heading=h.nr149nxrioi3)

[c.slli	8](#c.slli)

[c.srli	8](#c.srli,-c.srai)

[c.srai	8](#heading=h.dd4lbtm7uffu)

[c.lui	8](#c.lui)

[**2\. Resultados	8**](#2.-resultados)

[2.1 Programa ISA	8](#2.1-programa-isa)

[**2.2 Validación de cada una de las instrucciones	8**](#2.2-validación-de-cada-una-de-las-instrucciones)

[Prueba de c.addi	8](#validacion-de-prueba-aritmética-\(c.addi,-c.add,-c.sub\):)

[Prueba de c.add	9](#heading=h.p30f5lj5ka4k)

[Prueba de c.sub	10](#heading=h.bfubk7rtxd0w)

[Prueba de c.and	10](#heading=h.316hp6mqlh9)

[Prueba de c.or	11](#heading=h.igdak52iui8h)

[Prueba de c.xor	11](#heading=h.3rj81ua1gkig)

[Prueba de c.slli	11](#heading=h.qyugovrojb8r)

[Prueba de c.srli	12](#heading=h.2dqe5kgtwecy)

[Prueba de c.srai	12](#heading=h.3pb88ca2u47k)

[Prueba de c.lui	13](#heading=h.ovgurrmr8jie)

[**3\. Bibliografía	13**](#3.-bibliografía)

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

## **1.2 Cambios del Código** {#1.2-cambios-del-código}

### **1.2.1 El Módulo Descompresor (decompressor.v)** {#1.2.1-el-módulo-descompresor-(decompressor.v)}

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

### **1.2.2 Adaptación del Datapath y Control del PC (datapath.v)** {#1.2.2-adaptación-del-datapath-y-control-del-pc-(datapath.v)}

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

### **1.2.3 Fetch Desalineado en la Memoria de Instrucciones (imem.v)** {#1.2.3-fetch-desalineado-en-la-memoria-de-instrucciones-(imem.v)}

Dado que las instrucciones comprimidas ocupan 2 bytes (16 bits), el PC puede terminar apuntando a direcciones que terminan en 2 (por ejemplo, 0x...002, 0x...006), lo cual rompe el alineamiento estándar de palabras de 32 bits. Si una instrucción de 32 bits empieza en un límite de "half-word" desalineado, cruzará la frontera de la palabra de memoria actual. Para solucionarlo, se modificó la memoria de instrucciones para que concatene los 16 bits superiores de la palabra actual con los 16 bits inferiores de la siguiente palabra cuando detecte que la dirección está desalineada (a\[1\] \== 1).

```
wire [29:0] word_addr = a[31:2]; 
    wire        half_aligned = a[1]; // Detecta si termina en 2 (ej. 0x02)

    // Si está desalineado, une la mitad superior de esta palabra con la mitad inferior de la siguiente
    assign rd = half_aligned ? {RAM[word_addr + 1][15:0], RAM[word_addr][31:16]} : RAM[word_addr];
```

### **1.2.4 Limpieza y Bloques de Ejecución (aludec.v y pipereg.v)** {#1.2.4-limpieza-y-bloques-de-ejecución-(aludec.v-y-pipereg.v)}

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

### **1.2.5 Monitor Universal de Pruebas (testbench.v)** {#1.2.5-monitor-universal-de-pruebas-(testbench.v)}

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

## **1.3 Explicación de las Instrucciones** {#1.3-explicación-de-las-instrucciones}

A continuación se detalla la lógica de decodificación de cada instrucción implementada. Los comentarios dentro del código explican de forma explícita cómo se expanden los campos comprimidos para reconstruir la estructura estándar de 32 bits del ISA RISC-V.

### **c.addi** {#c.addi}

La instrucción c.addi pertenece al cuadrante 2'b01 con un código de función funct3 igual a 3'b000. Su propósito es sumar un inmediato con signo al registro destino rd, el cual también actúa como el primer registro fuente (rs1).

El proceso de descompresión realiza las siguientes asignaciones para construir la palabra de 32 bits (addi del formato I):

* Inmediato (instr\_32\[31:20\]): Se compone de 12 bits. Se extrae el bit del signo de instr\_c\[12\] y se replica 6 veces para la extensión de signo en los bits superiores, concatenándose con el propio instr\_c\[12\] y el segmento instr\_c\[6:2\].  
* Registro Fuente 1 (instr\_32\[19:15\]): Corresponde al campo instr\_c\[11:7\], que identifica al registro operativo.  
* Código de función (instr\_32\[14:12\]): Se establece en 3'b000, correspondiente a la operación addi.  
* Registro Destino (instr\_32\[11:7\]): Al igual que rs1, se mapea directamente desde instr\_c\[11:7\].  
* Opcode (instr\_32\[6:0\]): Se asigna el valor constante 7'b0010011, que define a las operaciones aritméticas de tipo I con inmediato en RISC-V.

```
module decompressor(...
);
 always @* begin
  case(op)
   ...
   2'b01: begin
    case (funct3)
     3'b000: instr_32 = {{{6{instr_c[12]}}, instr_c[12], instr_c[6:2]}, instr_c[11:7], 3'b000, instr_c[11:7], 7'b0010011}; // c.addi
...
					
```

### **c.add** {#c.add}

Esta instrucción se ubica en el cuadrante 2'b10 con un funct3 de 3'b100. Realiza la suma de dos registros estándar y almacena el resultado en el registro destino, compartiendo la misma restricción donde el registro destino rd actúa también como el primer operando rs1.

Debido a que este subespacio de codificación es compartido con las instrucciones de salto por registro (c.jr y c.jalr), el descompresor aplica filtros condicionales evaluando los bits instr\_c\[12\] e instr\_c\[6:2\] antes de asegurar que se trata de un c.add. La traducción al formato R de 32 bits (add) se estructura de la siguiente manera:

* Funct7 (instr\_32\[31:25\]): Se fija en 7'b0000000 para indicar una suma estándar (sin modificaciones de resta).  
* Registro Fuente 2 (instr\_32\[24:20\]): Se extrae directamente del campo de 5 bits en instr\_c\[6:2\].  
* Registro Fuente 1 (instr\_32\[19:15\]) y Registro Destino (instr\_32\[11:7\]): Ambos campos se enlazan al registro especificado en instr\_c\[11:7\].  
* Funct3 (instr\_32\[14:12\]): Se le asigna 3'b000.  
* Opcode (instr\_32\[6:0\]): Se establece en 7'b0110011, correspondiente al opcode de tipo R para operaciones de la ALU entre registros.

```
module decompressor(...
);
 always @* begin
  case(op)
   ...
   2'b10: begin
    case(funct3)
     3'b100: begin
      if (instr_c[12] == 0) ...
      else if (instr_c[6:2] == 0) ...
      else // c.add
       instr_32 = {7'b0000000, instr_c[6:2], instr_c[11:7], 3'b000, instr_c[11:7], 7'b0110011};
...
```

### **c.sub, c.xor, c.or, c.and** {#c.sub,-c.xor,-c.or,-c.and}

Este conjunto de instrucciones lógicas y aritméticas se encuentra agrupado bajo el cuadrante 2'b01 y comparte el código funct3 \= 3'b100. A diferencia de las anteriores, estas operaciones utilizan una codificación compacta de registros de 3 bits (rs1\_c y rs2\_c), lo que restringe el uso exclusivo a los registros x8 hasta x15 (el bloque de registros más activos de acuerdo a la ABI de RISC-V). El descompresor antepone los bits 2'b01 a estos campos de 3 bits para reconstruir la dirección completa de 5 bits en el banco de registros (wire rs1\_c y rs2\_c).

La decodificación interna utiliza los bits instr\_c\[11:10\] \== 2'b11 como selector de operaciones sobre registros, y posteriormente emplea los bits instr\_c\[6:5\] como un sub-opcode para discriminar la instrucción exacta:

* 2'b00 (c.sub): Mapea a la instrucción sub de formato R. Configura funct7 en 7'b0100000 (activando el bit de resta) y funct3 en 3'b000.  
* 2'b01 (c.xor): Mapea a xor. Configura funct7 en 7'b0000000 y funct3 en 3'b100.  
* 2'b10 (c.or): Mapea a or. Configura funct7 en 7'b0000000 y funct3 en 3'b110.  
* 2'b11 (c.and): Mapea a and. Configura funct7 en 7'b0000000 y funct3 en 3'b111.

En todos los casos, el opcode destino de 32 bits es el formato R estándar (7'b0110011), el registro fuente 2 es rs2\_c, y tanto el registro fuente 1 como el registro destino se mapean a rs1\_c.

```
module decompressor(...
);
 always @* begin
  case(op)
   ...
   2'b01: begin
    case(funct3)
     3'b100: begin
      case (instr_c[11:10])
       ...
       2'b11: begin
        case (instr_c[6:5])
         2'b00: instr_32 = {7'b0100000, rs2_c, rs1_c, 3'b000, rs1_c, 7'b0110011}; // c.sub
         2'b01: instr_32 = {7'b0000000, rs2_c, rs1_c, 3'b100, rs1_c, 7'b0110011}; // c.xor
         2'b10: instr_32 = {7'b0000000, rs2_c, rs1_c, 3'b110, rs1_c, 7'b0110011}; // c.or
         2'b11: instr_32 = {7'b0000000, rs2_c, rs1_c, 3'b111, rs1_c, 7'b0110011}; // c.and
        endcase
       end
...
```

### **c.slli** {#c.slli}

Ubicada en el cuadrante 2'b10 con funct3 \= 3'b000, c.slli realiza un desplazamiento lógico a la izquierda del registro rd por una cantidad determinada por un inmediato (shamt).

La reconstrucción a una instrucción slli de 32 bits (formato I) opera de la siguiente forma:

* Cantidad de desplazamiento / Shamt (instr\_32\[24:20\]): Se extrae directamente de los bits instr\_c\[6:2\], permitiendo un rango de desplazamiento de 0 a 31 posiciones para la arquitectura RV32.  
* Funct7 (instr\_32\[31:25\]): Se rellena con ceros (7'b0000000) especificando que se trata de un corrimiento lógico.  
* Registros (rs1 y rd): Se asignan utilizando la dirección de 5 bits presente en instr\_c\[11:7\].  
* Funct3 y Opcode: Se configuran en 3'b001 (SLL) y 7'b0010011 (Tipo I ALU) respectivamente.

```
module decompressor(...
);
 always @* begin
  case(op)
   ...
   2'b10: begin
    case(funct3)
     3'b000: instr_32 = {7'b0000000, instr_c[6:2], instr_c[11:7], 3'b001, instr_c[11:7], 7'b0010011}; // c.slli
     ...
```

### **c.srli, c.srai** {#c.srli,-c.srai}

Ambas instrucciones de desplazamiento hacia la derecha se ejecutan en el cuadrante 2'b01 compartiendo el mismo funct3 \= 3'b100, operando también sobre el conjunto de registros restringidos x8-x15 (rs1\_c). La cantidad de posiciones a desplazar (shamt) se lee de instr\_c\[6:2\].

La diferenciación fundamental entre un desplazamiento lógico y uno aritmético se determina mediante los bits de control internos instr\_c\[11:10\]:

* 2'b00 (c.srli): Desplazamiento lógico a la derecha. Traduce a 32 bits asignando 7'b0000000 en el campo funct7 para rellenar los espacios vacíos con ceros.  
* 2'b01 (c.srai): Desplazamiento aritmético a la derecha. Traduce a 32 bits asignando 7'b0100000 en el campo funct7, lo que instruye a la ALU a replicar el bit de signo del operando original en las posiciones vacías.

Ambas instrucciones resultantes adoptan el funct3 \= 3'b101 (SRL/SRA) y el opcode de tipo I 7'b0010011.

```
module decompressor(...
);
 always @* begin
  case(op)
   ...
   2'b01: begin
    case(funct3)
     3'b100: begin
      case (instr_c[11:10])
       2'b00: instr_32 = {7'b0000000, instr_c[6:2], rs1_c, 3'b101, rs1_c, 7'b0010011}; // c.srli
       2'b01: instr_32 = {7'b0100000, instr_c[6:2], rs1_c, 3'b101, rs1_c, 7'b0010011}; // c.srai
       ...
```

### **c.lui** {#c.lui}

Ubicada en el cuadrante 2'b01 con un código de función funct3 \= 3'b011, la instrucción c.lui carga un inmediato de gran tamaño en la parte superior del registro de destino rd.

El hardware del descompresor implementa una condición de seguridad crítica: si el campo del registro destino instr\_c\[11:7\] es igual a 5'b00010, la instrucción cambia su comportamiento para corresponder a c.addi16sp (manipulación del puntero de pila). En caso contrario, se procesa de forma estándar como un c.lui mapeando la instrucción al formato U de 32 bits (lui):

* Inmediato de 20 bits (instr\_32\[31:12\]): Se genera concatenando una extensión del bit de signo instr\_c\[12\] replicado 15 veces junto con el fragmento de datos localizados en instr\_c\[6:2\]. Esto inicializa eficientemente constantes desplazadas hacia los bits superiores de la palabra.  
* Registro Destino (instr\_32\[11:7\]): Toma de manera directa los 5 bits del campo de origen en instr\_c\[11:7\].  
* Opcode (instr\_32\[6:0\]): Adopta el identificador fijo 7'b0110111, propio de la operación lui en RISC-V.

```
module decompressor(...
);
 always @* begin
  case(op)
   ...
   2'b01: begin
    case(funct3)
     3'b011: begin
      if (instr_c[11:7] == 5'b00010) ...
      else // c.lui
       instr_32 = {{15{instr_c[12]}}, instr_c[6:2], instr_c[11:7], 7'b0110111};
       ...
```

# **2\. Resultados** {#2.-resultados}

## **2.1 Programa ISA** {#2.1-programa-isa}

Para evaluar la correcta implementación de todas las instrucciones comprendidas en esta entrega e igualmente el ISA hemos diseñado 4 programas de prueba para su validación. La característica principal de estos códigos es la coexistencia simultánea de instrucciones base de 32 bits y comprimidas de 16 bits. Esto obliga a la Unidad de Control y al Program Counter (PC) a adaptarse dinámicamente al tamaño de la palabra extraída de la memoria. Los códigos están distribuidos de la siguiente manera:

1. **Prueba Aritmética**: Intercala sumas y restas clásicas (`addi`, `add`, `sub`) con sus contrapartes comprimidas (`c.addi`, `c.add`, `c.sub`). Demuestra que la ALU procesa correctamente los datos sin importar el formato de compresión de origen. 

```
00500513 // addi a0, x0, 5 - a0 = 5
00200593 // addi a1, x0, 2 - a1 = 2
952e0505 // [c.add a0, a1] | [c.addi a0, 1] - c.addi: a0 = 5 + 1 = 6 // 
c.add:  a0 = 6 + 2 = 8
00b50533 // add a0, a0, a1 - a0 = 8 + 2 = 10
8d0d0585 // [c.sub a0, a1] | [c.addi a1, 1] - c.addi: a1 = 2 + 1 = 3 // a0 = 10 - 3 = 7
40b50533 // sub a0, a0, a1 - a0 = 7 - 3 = 4
0ca02423 // sw a0, 200(x0) - guarda el valor 4
0000006f // jal x0, 0

```

2. **Prueba Lógica:**  Evalúa el funcionamiento de las compuertas lógicas bit a bit, combinando `and`, `or` de 32 bits con `c.and`, `c.or` de 16 bits.   
   

```
00f00513 // addi a0, x0, 15   -> [32 bits] a0 = 15 (Binario: 01111)
00600593 // addi a1, x0, 6    -> [32 bits] a1 = 6  (Binario: 00110)
8d6d0505 // [c.and a0, a1] | [c.addi a0, 1] - c.addi: a0 = 15 + 1 = 16 // c.and: a0 = 16 & 6 = 0
00f00513 // addi a0, x0, 15 - a0 = 15
8d4d0585 // [c.or a0, a1]  | [c.addi a1, 1] - c.addi: a1 = 6 + 1 = 7 // c.or: a0 = 15 | 7 = 15
00b57533 // and a0, a0, a1  - a0 = 15 & 7 = 7 
0ca02423 // sw a0, 200(x0)  - guardar el 7
0000006f // jal x0, 0 

```

3. **Prueba de Desplazamientos y XOR:** Valida el funcionamiento de los desplazadores lógicos y aritméticos (`sll`, `srl`, `sra`) junto con la compuerta `xor`, empaquetados en bloques mixtos de alta densidad. 

```
00200513 // addi a0, x0, 2  - a0 = 2
00300593 // addi a1, x0, 3  - a1 = 3
00b54533 // xor a0, a0, a1  - xor clásica: a0 = 2 ^ 3 = 1
05328da9 // [c.slli a0, 12] | [c.xor a1, a0] - c.xor:  a1 = 3 ^ 1 = 2 // c.slli: a0 = 1 << 12 = 4096 (0x1000)
00255513 // srli a0, a0, 2  - srl clásica: a0 = 4096 >> 2 = 1024 (0x400)
812d0585 // [c.srli a0, 11] | [c.addi a1, 1] - c.addi: a1 = 2 + 1 = 3 // c.srli: a0 = 1024 >> 11 = 0
00b54533 // xor a0, a0, a1  - xor clásica: a0 = 0 ^ 3 = 3
40155513 // srai a0, a0, 1  - sra clásica: a0 = 3 >>> 1 = 1
85050505 // [c.srai a0, 1]  | [c.addi a0, 1] - c.addi: a0 = 1 + 1 = 2 // c.srai: a0 = 2 >>> 1 = 1
0ca02423 // sw a0, 200(x0)  - valor final: 1
0000006f // jal x0, 0
```

4. **Prueba LUI y General:** Un bloque ininterrumpido que encadena todas las operaciones anteriores e introduce la instrucción `c.lui` (Load Upper Immediate comprimido) para verificar la carga de constantes en los bits superiores operando en un entorno híbrido. 

```
00100593 // addi a1, x0, 1    
8d4d6505 // [c.or a0, a1]   | [c.lui a0, 1]  
00154513 // xori a0, a0, 1    
952e0585 // [c.add a0, a1]  | [c.addi a1, 1] 
40b50533 // sub a0, a0, a1    
8d6d8da9 // [c.and a0, a1]  | [c.xor a1, a0] 
00255513 // srli a0, a0, 2    
050a8129 // [c.slli a0, 2]  | [c.srli a0, 10]
0ca02423 // sw a0, 200(x0) 
0000006f // jal x0, 0
```

## **2.2 Validación de cada una de las instrucciones** {#2.2-validación-de-cada-una-de-las-instrucciones}

### **Validacion de Prueba Aritmética (c.addi, c.add, c.sub):**  {#validacion-de-prueba-aritmética-(c.addi,-c.add,-c.sub):}

![][image1]

La simulación confirma el dinamismo del hardware híbrido al observar la señal **`PCF`**, la cual arranca con saltos de 4 bytes (`0, 4, 8`) para las instrucciones base de 32 bits y cambia instantáneamente a saltos de 2 bytes (`8, a, c, e`) al decodificar las instrucciones comprimidas (RVC). A nivel aritmético, la señal **`ALUResultE`** demuestra una ejecución matemática exacta y continua: el procesador carga los valores iniciales **`5`** y **`2`**, los escala a **`6`** y **`8`** mediante sumas empaquetadas de 16 bits, alcanza el pico de **`a`** (10 en decimal) con una suma de 32 bits, y desciende correctamente a través de restas pasando por **`3`** y **`7`** hasta llegar a **`4`**. El bloque finaliza su ejecución levantando la señal **`MemWrite`** a 1 para escribir definitivamente el dato **`00000004`** en la dirección de memoria **`000000c8`**. 

### **Validacion  de Prueba Logica  (c.and, c.or):** 

![][image2]

- Este programa exige al hardware manipular bits de manera directa. A partir de los valores iniciales `f` (15) y `6`, el procesador ejecuta una compuerta `AND` comprimida que actúa como un filtro perfecto, limpiando el registro temporalmente a `0`. Posteriormente, el hardware demuestra su capacidad de recuperación de datos aplicando compuertas `OR` entre los valores `15` y `7`, restaurando la máscara original. La precisión de estos cambios demuestra que la ALU decodifica las funciones lógicas correctamente sin importar si provienen de 16 o 32 bits.   
- El aspecto más destacable de esta ejecución es la estabilidad de las señales de riesgo (*Hazards*). A pesar de intercalar instrucciones comprimidas que requieren expansión con instrucciones base consecutivas, las señales de `Stall` se mantienen nulas. Esto evidencia una Unidad de Control altamente optimizada que logra enrutar los registros fuente hacia los multiplexores de la ALU en el ciclo de reloj exacto, garantizando el máximo rendimiento del procesador. 

# **3\. Bibliografía** {#3.-bibliografía}

1. Harris, D., & Harris, S. (2020). *Digital Design and Computer Architecture: RISC-V Edition*. Morgan Kaufmann.

2. RISC-V Collaboration. (s.f.). riscv-gnu-toolchain: GNU toolchain for RISC-V, including GCC. GitHub. Recuperado el 23 de junio de 2026, de [https://github.com/riscv-collab/riscv-gnu-toolchain](https://github.com/riscv-collab/riscv-gnu-toolchain)

[image1]: <data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAoUAAADsCAYAAAACTdxvAAByH0lEQVR4XuydB5zURPvHc5VrcNzRjqMfvUgHpRcVpClKEysqxb++CoLlFbFgVxBQpCPYaFIEaUqVjoUiUgSRIirdhq8FxeefZ7KTm51kb7O32bvZvWc+n+9nnszMZpJN+22SnZ+maRoQ7sKTXE4QBEEQBGGHrhoY335r5HfcoUG5ckaMOY9FxDIer19v39YJmrxQRPDwJJcTBEEQBEHYwYXZkSPZ8d13m2INBg/2FnBZWUY+d252uzvvNNru2ePdduBADZo21WDWLGMaY0Rs4+nHumBEcPAklxMEQRAEQdjBhZkoCrt0MfK9e73bIIGIQmTOHKNu9GgNypTR4MMPrW00eaGI4OFJLicIgiAIgrADRRk+Mu7ZU4OjRzUYNkyD6tWzyy+7zBRuLJ8/3yhHEbl1qxFv2qTB0KEadO/uLfaef95bFFatqkGdOiQK8wSe5HKCIAiCIAg7ZIGWH2jyQhHBw5NcThAEQRAEYcfLL7+c72jyQhHBQ6KQIAiCIIgwxFJABAmJQoIgCIIgwhBLAREkJAoJgiAIgghDLAVEkJAoJAiCIAgiDLEUEEFCopAgCIIgiLBj3rx5EIl8/PHHcOLECUt5XkCikCAIgiCIsOPChd8gEvnqq6+YMNu+fbulLtSQKCQIgiAIIuz49ddfIRIRRaFcF2pIFBIEQRAEEXb8/PMvEIlwUbht2zZLXaghUUgQBEEQRNjx008/QyQiikK5LtSQKCQIgiAIIuw4f/5HiEREUSjXhRoShQRBEARBhB3nzp0HC2e/gmv0yv9beAC+3/QUTD943NpGcUxRuHWbpY6TWf8GlqdktfEqH1KuBHxz1treKSQKCYIgCIIIO86ePQcWzhzQRWEslCyaCd9t1EXhV8egTeOioJWpDyc2vA71GjeGBv2GQqaWDCfOnIPBPVvqM4uChVsPW+eVT3BRuFUXhXId54aamXD2xOfQ7sGFcHzHR+wLuWn0ehisi8Kvz3wIQ6avgWkDO8O2M2fhppa1Ia18W8s87CBRSBAEQRBE2HHm9FmQOX1qP3TUCsOhHTPh7tFDYOqBozB38jNQOSURNi9/HQaO+xAqxNaEdW89BMsO7RBmWMMyr/wiWxRutdRxNs38Lzz+zF2w79QZOPH1DnhywH/0dWjBROGhUyth8LQ1MHVAJ9jy6XvmOo7eesYyHxlZFPK4T58+Xl8+jqWIKSkpCdLS0lj80UeGOBU/nxeMHz/e7BNTt27dLG0wrVixgsVPPvkkm+7atSubPnXqlKW924wbN47lmDp37sziM2fOeLXBNHbsWBa/++67bBrjs2fPwp9//mmZZ6jAVLlyZTMW60aPHs3yOXPmsLqsrCyz3Z49eyzzCgV9+/Y1txmmXbt2edUPHDiQ5Tt37jSXv0KFCmbM60MN72/Tpk0sf+CBB7zqDx06BMWKFYOEhATWduPGjax86NCh5mdDzYEDB1g+ffp0ePDBBy398um6deuyGNvh9OTJk6F3796W+YWCli1bwpQpU1g8depUyzIePXqU5ZhwuTCeNm0am65Xr55lfqEA07Bhw1i8YcMGyzIiN954o2073P7p6emW9qEAx6LF46VSpUpsWl5OTIMGDTLjihUrmrF8nIUKvk8iuJyYcLnvvvtu2+XFHM9DmObOncumR40aBXfeeadl3m4hnlswxnMSxq+88oplGc+dOwdVq1Zl5bNmzWJlY8aMYdO4b8vzdou1a9eay4LpqaeeYvGyZcugWbNmlvZdunRh7fD6iNPLly9n0yVKlIB//vnH0t4NZsyYYS7jgAEDWL5y5UpWxs+NYnvx3Pjhhx+ymB877Jp16uQZsLIPOuiiEONWCRpM2XcUYqKioKguCtcvHg8Dxq6ECiWawto3H4SlP5yGIgmxbIZpbZ+xmVf+IIpCuU4kpnJrls8ZdjlERcXr61EP7tNF4Vc/7IGYaA0SC8XBJn0dU+JiICo6BnbqsTwPGZ7wOylatKgZByMKMSUmJrKNh2nRokVe9cHwxRdfsJz3iSlYUYgHg9iuV69elvkFwnvvGcL86aefZicNN0QhnlQwx5MMpqZNm1r6zQ3XXXcde5fVDVGIJ3E8SfN2GRkZcPLkSUufgbJq1SpXRSF+ntc1adIk6GVEAYV5fHw8m68bopBPY0Ixgd8lfr9y307hJ1vctzC5JQpRhGFCUYbL+PLLL1vaBEKDBg1YzpfDDVGIy83nMXv27KC3N54bsV8c0gun3RCFmHA/wBiHJgt2GUeOHMnyJUuWsHm7IQrl48yt41vcZm6LQrEdLi8XQLlBXBY3RWGnTp3Y+R9j3N9z851evHiR5eKyXLhwgeVuiEKxHYrP3CzjN998Y86Ll+F8uJ7IlSj84ftTEIlwUbhly1ZLXajhCb9kO1HIT/K5FYWXLl0y27lBTqIQD/o//vjDLM+NKMTltROZgYCiEMVelP7jBKdlUYh9YI4pN6IQP1+9enVLv7kFkywK+TIGIwqjo6PN+eUW/A5xPnaikN9Nki9WGDsVhfwiJPcbCCigihcvzmJMsijkJ/zcikI89vA74OIiN/CT7WWXXcbmKYtCcZ/EPFBRiBczXEYu0nILF4VcqIiikC9jMKIQ14fHuQXPjZhkscfr+bGUW1Eozy83cFGIbNmyxSIKxe2dG1GIn3fj+EaciEJ5/wxUFOL5C5eXn89yA+8bsROFfBmDEYV4PRD7cYosCv/991+zThSFsbGxULJkSRbnVhTydvIy+EMWhSNGjGC53Z1C/j35FYXff3cSIhFRFMp1oYYn/JJRFCK4cfiGRBGIOZZhHY9jYmLMWFb3WIYXc8w5Yn0woCgsUqQImycKT+ybzx8Per7DpKammuWYJycnm7E8T7GdG8uLohD7E+clzpPHhQsX9qrH9eKxvAxuLyNH7pcLWbvljYuLM2P8nuVlwOmUlBSW4/4hzi8YxPXFHyQ85tuUt8Ec9wEei/sAB+/myfsGnijlPgOB3ynEeWH/POb1+J3wMl4uHmeY8+OMI9bx/V3uNxD4MYrzwe3IY/m44MctxmK/4rJzcFvw7cy3u9xvoHBRKC4vHic85u0wxm0plov7Jwe3NbbDcvyOMef7e25BUcjnhdOY83MjYndu5G359yXPk7fl36M4v9zARaH8ncn7p7geeBzwWDzOxM/znMPnFwx8XjzmxyPG4vUH80D2TzxHubV/8vnz+Yn9ise32F48zjDn+6E4X9zO2A7ngdczrOf7eyCgKOTbjPcjLqPYr7gPyPunuA+IYBkuH/8e8biS2/gDRSHfZuKyYS4fF+J3J2sQcR/QTpz4ASKRbFG4xVIXamRRKG9I1eB3ClWGPz4mCgZcFKqM/MNNVbgoVBn51RoVEe8UEpEPv1OoMvxOoat8e/w7iERMUbh5i6Uu1OQkCm+44Qav6ZkzZ3pNN2rUyGu6bdu23htMol+/fpYyf/DHphxZFN5///1e0/7u+lSpUsVSxh/v+oLfbufceuutXtP4qEOcdkMU8l9KHPn9NHxhV5zGxxjitL9tkRvkPvjjW86kSZO8puV1kLHbFviOn1wmIn+3/rZFbpC/a3mfuv76672mZVEo77Pt2rXzms4N8vaUH4PJ20I+dmVRyB9V5oS8LR577DGvafkdWXlblCpVyjJPEbv3YmVROGTIEK9peVsMHjzYa5q/3sDZvHmz13RumD9/vte0LArlbSHTo0cPr2l+hzMQGjdu7DUtbwt5GWVRiK/WyPMUufzyyy1l/DE4R97H+Os5HHlbyOeD3HDbbbd5Tcvr2aZNG6/pa665xmv6rbfe8pqWtwVSqFAhS1lOyNt7+PDhXtPyMvI/VHD4o3yR9u3bW8pE5P26e/fuXtOyKJSPm5o1a1rm6Q/5+JWPb3k95X1OPn84EYX+jg15H9SOHzsBkQgXhZt1USjXhZqcRKF84fj666+9pjt06OA1je/QeG0wiWeeecZS5g/+fhZHFoXyicffTtWwYUNLmT9RiO+nidP8X12c06dPe03LwiU3yCcqWajg+2niNH8/jcPfeXETuQ/5nUJ5W8jrIGO3LfD9GrlMRBYi/rZFbsD308RpeZ+ST7iyKJT32ZtuuslrOjfIxxa+dyZOy9tCPnZlUcjfFcwJeVvIgtvftuDvp/kC32mSy2RRiO8UitPyDw35HUb5nUI3RCG+IyZOy6JQ3hYy8rug8rZwgix25G2B7yGL0/IF2k6IiPD3rUXq16/vNS1fkP/+++8c6+V3EnODvB7yesrbQv6eZCEibwsEH4vKZTmB7/iK0/y9Ro68v+D7juK03ba4+eabLWUi8n4tC3BZFMrHjd0fTfwhi0L5+Ja3xQcffOA1LZ8/5G1hh79j48svv5TLrI0iAfwlwYVZXiOKwkceeYSJD5XBf+bJZaqBL87KZUTk8uyzz1rKVAP/VCKXqchzzz1nKVONCRMmWMpUA/9lLZcRkcvBgwctZaqxY8cOS1mwaLKgiRRUEYXxI+JBe1hzF5s+g6Hnsp7WPoIlS7P0EwxXjb/K2kewNNYs/QSN3EewdNCsfQSL3IcbyH0ESXqNdGsfwWLTTzDEFIqx9uEGNn0FQ/GXilv7CBabfoKh8uTK1j6CxaafYGg8pLG1j2DpqFn6CRq5DzeQ+wgWef5uIPcRJP0P9bf2ESzJmqWfYOi7vq+1j2CRO4kUVBGFKfNSQHtWc49nNEt/QfOFZu0nWDpr1n6C4T3N2kewPKBZ+wmWyZq1n2CYpFn7CJY3NGs/wSL3ESx1NWsfwSL3ESwJOi9o1n6C4X+atZ9g+Uiz9hMM32rWPoJli2btJxhCcZ4cqbl/fE/RrP0EywzN2k8wzNasfQTLO5q1n2AYr1n7CJZLmrWfYCmlWfsJhm80ax/BYunEhmKXZ0Bao5JQ+7Gm0Oj14F/wzguUEoXdNPd4UrP0FzQoCuV+giUUolDuI1hCIQpx+8j9BEMoROErmrWfYLhVs/YRLCgK5X6CoZdm7SNYUBT21Kx9BUOoRKHcTzCEShTK/QTDEM3aR7CgKHxKs/YVDKEQhWM0az/BEApROF2z9hMMoRKFcj/BcK0WGlEo9xMslk58wEVhtfu9X5RFktJLw95Rl8Ozn/5sqcsv7ERhx1e3Q5JWGQZcE/i/hgKBRKFGotAtSBS6A4lC9yBR6B4kCt2BRKF7WDrxAYrCJx/sAv/39HVm2WPLPgctKdNLFPabugNSbT6f19iJwmOfv87y+WNy/kdvsJAo1EgUugWJQncgUegeJArdg0ShO5AodA9LJz5Ib1QK/v58HPy5uKdZtnvJEywXReHIeta/hucHtqJwhyEK540OzofXHyQKNRKFbkGi0B1IFLoHiUL3IFHoDiQK3cPSiQ+SyheGk69Vgw3PZg+OOumzE6All/EShS2eWAGZNp/Pa+xE4W3vHoUUrSZ0a+g9cLLbkCjUSBS6BYlCdyBR6B4kCt2DRKE7kCh0D0snEYKdKMwrSBRqJArdgkShO5AodA8She5BotAdSBS6h6WTCIFEYQCQKHQPEoXuQKLQPUgUugOJQvcgUegOJAqdo4wofC3FEB9u8bTOPJf5WbP2EywbNWs/wYAXIrmPYNmlWfsJFtw+cj/BcFiz9hEsz2vWfoIBBzyV+wgWFDJyP8EwTLP2ESwLNGO+cl/BgKJQ7idYZmnWfoIBj0W5j2BZrln7CYbHNWsfwbJPc//4xou63E+wuH18oyiU+wiWUZq1n2BAUSj3ESwoCuV+gmWJZu0nGH7TrH0EiyxoIgVlRGFKiqVeNZx4tuY3Tz75pKWMiFxks3oVkf2bVaVKlSqWMtVo10798W/79etnKSMil1WrVlnKVGPWrFmWMhewFEQEJAqdQ6KQUA0She5BotAdSBQWLEgURhjKiEK3be5CQNddXS1lqtF6Q2tLmRehsLUi8g0She5BotAdSBQWLEgU5gDZ3AWGRRTKL3Iqxn2r7rOUqUbf2X0tZV6M0CzbgQhfSBS6B4lCdyBRWLAgUeiHnGzu/LFpcn9LWaixE4URYXMXAkgUEqpBotA9SBS6A4nCggWJQj+gKGw8vBlcNqSJWTZ99ZewackTcMfMPXDkyBHIiI+GT/d8BbPubQFNBoyCI98fgtptb4I/fj1rmV+osROFm08sZPnSSWHsaBICSBQSqkGi0D1IFLoDicKCBYlCP9jZ3E1bsQS0ElXh4h9/wB86y+9LhxO//g1x0dHwz8W/WNndzdW5U3hsxwSWh7XNXQggUUioBolC9yBR6A4kCgsWJAr9YGdzx0RhVDScOjRZn46CFilJUD5NgwUvdoGNhz/Ry8pABb3d7sWPW+YXauxEYUTY3IUAEoWEapAodA8She5AorBgQaLQAUWSEyGxUPaJsETpDJYXzawMlStXhuioKMjS84S4aEhILcHKsD6jgpHnJXaiEOHLFEpIFLoPicKCBYlC9yBR6A4kCgsWJAojDF+iMC8gUeg+JAoLFiQK3YNEoTuQKCxYkCiMMJQRhW7b3IWAPtv7WMpUo+OHHS1lXqAvqWwBRIQtycuTLWWqET0/2lKmIikrUixlqlFyfUlLmWpU/LSipYyIXNqcamMpU43Lj19uKQsaWdBECsqIQnI0cQVyNClY0J1C96A7he5AdwoLFnSnMMIgUegcEoWEapAodA8She5AorBgQaIwwiBR6BwShYRqkCh0DxKF7kCisGARDqJQ+0azWr4Gi6UTG2r9twkUb5YJdZ64AhpPbG+pVxEShc4hUUioBolC9yBR6A4kCgsWYSMK5T9dBoulEx9wUVj9gYZm2euf/W7G6dWfhWKFC1k+J3J62X0s/+nIfCgSrcF1L2R/6Y+/tQC0QoUh2eZzucGXKBy39htLmduQKHQfEoUFCxKF7kGi0B1IFBYsSBT6AUVh54d7QMcnu5tlL83bCVNvTYWo5GLw+87nmSjsMHIxfHPyAMTp9SuWvAf7Pn4bPv/mKNxRLBlGf3qKfe6e+d9Bk6zisOrDKdDnuQ9g2/G18Prs9+HJZd/BiS82QZEKl8E333wD5ZNiLMvhFF+icPSWw5YytyFR6D4kCgsWJArdg0ShO5AoLFiQKPRDxSurwhszZsCSJR9AkSJFWNlL8zbB8Pl74boJOyE6Np6Jwr///AN+//13uLKaBvd2KAud736dtf3q/aGQljEEYgYuh3itASwe0QCev6YRE4VYj6JQK98U6uox/PsPm8fKYeUsy+EUEoXOIVFIqAaJQvcgUegOJAoLFiQK/dBsRkfYuHETbNu2DdJrlmBlKArL170LTm95xhSF02+ubn5GFoVxRUrAB19dYtO7jy+FtjXTbEXh3vNbLP0HColC55AoJFSDRKF7kCh0BxKFBQsShQ4oXKSIl8hJL5mp5zGQgtNRURATHQXJxcuaJ/QiibGQVKQ4i8uVSgX0R84qV4xNY7tYPU9JN6zyipcspefRkFWxPERFx7B54PzkZXCKL1FYLDP3dx+dQqLQfUgUFixIFLoHiUJ3IFFYsCBRGGH4EoV5AYlC9yFRWLAgUegeJArdgURhwYJEYYRBotA5JAoJ1SBR6B4kCt2BRGHBgkRhhEGi0DkkCgnVIFHoHiQK3YFEYcEiHEQhOZoEAIlC55AoJFSDRKF7kCh0BxKFBQsShRGGUqJwr14+jiAIR6wQROF4m3oV+EYQhe/a1KvAJY0tHxOFy2zqVUHziMJXbOpU4S5BFB6yqVeBbVr2deisTb0K6Me2uYxpNvWqoAmiUK5ThUKCKJTrcouxbcwgolBKFNa2tiEIwgedPKKwuE2dKmSFyZ3Ckh5R2MWmThVaeUThUJs6VZhOdwpd50ebMlU46hGFZ2zqVOFPjyjcZFOXWyqzPLsAD8z09HRLw4lrdsGE1Tvhqk7dYMrG/dCkeStW/tCCQ7Bp0ybYNPMOKCV9pmqNqpb5pFa6Fa5N9R5m5oPZ482465iPYUhrDQ7q8/xi3v+xssZX3AYtKmW3n/XxAVg/+wmo2n8CzLrFe/4idqIwpdxlsHXTDsgqkgA9hk+GL3euY+XT1h+GT7Z9wuLnVx2DYwcWsfijDTthxiN9ID41Az7ftB2urej93Ty6ZD/s2/m+pW8vUXiV+o+PI4WWLVtC8eLGEEgYY56ammrGYnmNGjXMGPPLLrvMjMVyPj8ib8nqkWXc3bKp48jbNSEhwau8TJkyXtuyefPmLG7cuLFXeaVKlcwY6+R+fBHfVheFH1nLRcR+MU5LSzNjsQ3mUVFRZlyrVi2vZcRpHrdo0cLSj08+0EVhr5wfH+P8nPSLy8djzFG48xjXy26dHDFBv/bc7f/xMZ8nbi9xGfk2w1gsx+0vfg73Dx43aNAgsGXU6fdEP9AesZaL4DzLly9vxnXr1jXjuLg4M8Yc24nLe/nll7MY80CXzWSMxu5qWsoFypUrZ9svxtyYQuyfx7GxsWaM6yXOo3r17PGJ/fKOzrU25QJ43hXnz2M8T4vleB7nMf+sXSzOwxEZuihcrYvCojZ1AnZ94Y8wsV/c13gslmdkGMPx2c3DKbMW6qKwrnV55OPRMXNZ7l3Yo0cPKFq0qFcZisJXZsyG2fMWwKS1u7NF4bQVRpvENPj9z+VQqO1LcPjwt5BRKBZ++e1X+E+32rDv+GHY8OYw1u6jk2tg55/rWYzjFB45fBg+WzABOg2eARuPb4Suj79h9vno2l898XWGKMzqAx1bdoFmelnjzmNYXaCicPOJBSxfOrEXTPxPVz2uAw/2aQIdWX0azL4zBe6Mj9XjHlDrmqFQUS+/65WPYNCEt9jnluxbD8VqNNPX8RtYcnc8rHi2CSQ3exTKSX2LojDp6yTLshGhAS9umMaOHcum3333XXM7nD17Fv78808W48GCacwYz36k/9rCVLWq8UOGt2vVqpX5eSJvKfdVzuOJ3nTTTSw/dOgQFCtWjF3wMW3cuJGVDx06lE337duXTX/99dfmtsS0YcMGFg8bNsws//TTTy395ETc13F+LxpHjhwx548XUkz8Hd7JkydD7969Le3q1avH4mnTppntMNWuXZstN2/nlApfVbCUiWA6evSoGWN/GGP/mHB5eB0uJ8a43Hw5cH0wcQGEqXLlypZ+cuKKfVdYykQO69cKzG+88UY2f9xuOM2/D9z+eEMDtzOW43bHhPsBTuN+wdvh/oJp5cqV5n7khB5f9ABthLVcpH///mzegwYNYtOYKlasaMa7du1iMb8+DRw4kE3v3LmTTfN2OI0xfo/8h4QjemvsrqalXADTXXfdxeIvvvjC7BfFNqa5c+ey6VGjRpnt9uzZY7bDHwNiOz5PuR+fNNZZZ1MugAnPvxj/8ccfcO7cOXZ+xsQfmeL5GxMXP3jexvM8xp06dWLnf4z59YAfa055a5tx3fdFs2bNWP7333/D6dOnWdylSxe2TPwd+OXLl7PpEiVKwD///AOnThlWv127dvVqt2LFCvO4l/vJiTGfGtcwZNKkSSx/44032Hz4jY5c4F2A6hVXTCx7dfk22LZ9O7z00ih47b0V0PgKYyOYolBLghUX97IYD8wHWtWA6QtnsOmkwkWh77iFoEVFw4YR9aHJi19ClF4+8YtNrH7jsjeZKMSYi8JF589Dh+LGINemKMS40c2Qpee12j3IpgMVhcc+N9xV1s/+L4y9vbUeZ8LLT9wFtVl9Emx9qQ20jkO/5YbQ8P5JUEwv7/7YXHh42jvsc29t/VwXtvvM+bUZ+RH8/PEoiJb65olN+7loEO5BojCCEH792hEKUYhw8eGIBJsyCTdFIcbR0dHmhcUxDWzKBDC5LQp5O8f0sSkTcFsU7t27Fy5evBjYKwAjbcok3BaFuE683C0wuSkK77nnHli4cKGln2DA5LYo5MvvmIs2ZQJui0KsD3gZcUgaTxwSUYi/Sjp27Cg3YEyf/gbs3r0bypbN/gXPRWFaxgPwwcBY+OTnZWzaFIVlr4G2sTEwbNYmKFv7dnZAItdmFIWlX3/G2m5c9pZFFDL6LzWcUkRRGN0Yeulx26FT2XSgovCtY0afr/RpBW+OuQ200u2gfUxVuKemXp+UCbfHJMDYlvqv//ojICOmO9RL12D43FnQ8xHjJL7m45dg9/GPzPk9WgldWOpAp/pcwBrwhHHK3/T4OK8gURg5ZF3I+d/HbovCXr16selARGH8JV1QFLOWi7gpCuvXrw/Hjh2z9OGPKhdyfnyMKb9FYbvTOT8+dlsUYgr0TmG/I/1AG2stF3FbFGI9L3dEf53lNuUCmNwUhXyecj8+aaVz2KZcAJPbonDr1q2WfnJi1fqc/33stijk5zC5n5yYtS3738c5iUL+iszbb79tlt1+++2W+XnInsBfoTYNfJJaqjzrzBBvGhRKy4RK5UpAakIcJKeVgqLJ8aw+Nb2kLhyN9yyQChloeWfUlSpRDBI9VniGKIxi5WWLGe8H4R28hFg9j02GRD0vUUb/TNFEVheoKET4l1OocDGoVNZ4pp+eWQkqVTDEbuFSFaFSaVw+DTLLV4IiScYvSf656Jg4FhdLiILi5XD9rY+5eMI4HIakIQjVYH80wX9Q2tSpArvLdM5arhSnw2BImo1hNCTNEGu5UkzT6WxTrhL69vb8oUFdKnr+aFLCpk4hmEBuaS3PNYZYt6nIJ1LL1YCyDh+3JpWuBhXTreUcX6IwL7CIwixrG4IgfNDcIwpb29SpQhmPKPTzmDvfaeMRhW5eONymj0cU3mxTpwpPeERhSZs6lSivU8SmXCWqaWw4FW29TZ0qrPKIwo9t6lRhm0cUzrOpyy0dWW5TEQEoJQrftrYhCMIHEz2iMF6P42zqVWCWMCRNRZt6FVissYsvE4UTbOpVId0jCp+zqVOFB4Uhafz8Aznf6CvEr9nUq4D4Q6+HTb0qtPeIwqtt6lThOo8obG5Tl1uSWG5TEQEoJQpt2qgEOZoQqkGOJu6h/ONjLYweH9uUE5EJOZpEGCQKnUOikFANEoXuQaLQHUgUFixIFEYYSolCtLnDf60RBEEQ3miCzZ1cRzhHtLlDJw65XgVkmzu5nnCOaHMn1+UWY9uYQUShlCgkmzuCIAh7wsHmjnAflW3uwoG8sLlr27YtG8NJbujL5u6jl3voeQz8uPNVNj1o8XnzMxMWvAlaSklIkOZ16fwhNmbUzkWPQyGprl5VY4gYk75vwsRBtWDae+v0z3wBJVI0SErLgIVrl5ptXlx93LCla3kvbHitp1luJwpTyteFLRt3QOUiCdBz+GTYsyPb5m67x+buBS+bux0w4783QnzRDPhs4zZmc1ex2bWwedNOuLeeYaGUedc0qC+NVeYlCq9W//ExEd7w8bxwnDYeoyUZj9EJg8eY4zSPuXUZxtzikrcliDzhdV0U/l/ePz7G/Vw8Lrhlmrj/8xjHyOMxWrCJnxNjbl2WbziwuUN7PXGZr7jCcJPBmNvc2X0HaNPHYxyT0u67cwT+8fI6m/IQg8vZpEkTM05OTjZjsQ3mOGYgj9GmTlxXPp6tOL/8Qra548uJLjjiejnGzubuwQcfNC8UHBSFE1fvgJdnzIUpG/aZonDdppkQnVoRtnxqDMi4++wnULxCNahRpzKUL1MKKnT/L1xTvRLEFEqGOnWMC9Gl5cZgnZpWHXpdXglKVagCdWpmQaHC6bBz/pOgRcfpbetAErbRRaG4HI/1qQs9n58Iy79YytqVTEqCOb1jQav5CFQqoou7J3MWhbOOf8vy957qDItn/B9oJdtAv8uqw+P4j6jE0vBSy0SYe2M8m19WyR5wRVkNHnl3FfQePo99bvOuufDh9zv1vuNh10VjcNZNUz7IWRTS4NVECOHvg+LApZgaNmzoaCBkbIfTvB0OjIxp6lRjYPgpU6ZY+iKIUOFv8OpQcM011zgeCBnTyJEj2UDImLj/9F9//QVnzpxhcefOnc3jKd8IYvBqeVBqHLz6zjvvZHFOg1ePHj3arHOEg8GrQ8HmzZvZcuK7wDiYNCYcXBrr8J31wYMHs3jLli2sDkVwyZIlWbxsmWHM8dRTT7Hp1q3RES3AQbtDgNPBqwPEuyAQm7uuY5dCtWZPQVrp+2FMixhYfE8xeGipMaL8whnPgdboFmZLt3j7m5CeXhbevUUUhbqIe6A1RMcnQnr7Qazd5ikDWDnesfjn4FhTFA59cz2c/3oZJMQZg2szUYjzSCwKLWOwrCHUr5DiVxTm1ubuoanGyOhoc3d81XA9jobR+y7CHW8d1ONuOYpCsrkjQgmJQiIi8GNzFwrcFoWFCxeGW2+91dKPamDKV1GYT7gpCjHGu4TffmvcaMo38tPmbpp+8TFs7sqaZel1roSlGz4DLSkdLv29HNKTY21F4eZNhm0Ski0Ku0OT8lEwYVBnKHvN/aYorHXbROaNfOngOMudwiVPGpZEpijUEpkY1Ro8DqWi/N8pNG3uents7jJzsrm7Ltvm7mHjgrr245dgCdrcRcfD3osroFChQjo3QNOMWK9+eMKY7hQSoYREIREJRMKdwuuuu87SR55Ddwp94qYoxH0CpzHJ/eQlTu8Ucke2d955xyxzZHOH70rIj445+AVZhleJLg5fffBfQGu6IesusfcHvURhXGU4//kiqHnVzXDy5CmI08sv/fGzHp+E59s0Zu2WfP4tTJwxm4nCpccuQJGsJnDyu6O6KMy+U/jpsdP6Z85DUiG8i+cRhcll4OnGGgxd8QtcWPc0K/cnChNSS8Cpk2ehUGw0XD1kApzfY+wQr23+BU4f3c/iB5b/ZM5v81dn4eEbm0JsQjKcOXkaUpNioXStZnDq+5OQmcZt+HK+U5iSRaKQCC38PSb8kcJjPI55jO+X8BhznBY/x2P8vFxOECFnsS4Ku+e9KMT9XDwuihYtasZiG8xTU1PNGN83Ez9nF+cbE3V62pQL4HVcXGYUPjzmwyzZfQdog8tjfJpn9905Av+B3NimPMTgcqIY5HFsrHEzx25dY2JizBj/ZyGuK3/vUpxffjFrri4Km2ZP8+UUrwUIrg/m4nZKTDTsgr0w/sFu7UgZ0ipA9UzjZVC/pJaBGuWzV9hOFOYVXqKQbO4IgiB8Ew42d+EC2dwVHMjmLjCUEoVkc0cQBGFPONjchQOizd14m3oVEG3ubrCpJ5xzrUcUNrOpyy1kcxcaLKKwq15+i7r0X9/fUqYa1y+83lJGRC4lHyhpKVON2NtjLWUqUmpYKUuZUmgeUdjIpk4hWk9pbSlTDn4dkstVgi8jepvLdQrxyJePWMqUIkYYvFquyy3GtjGDiEIpUWjTRiXI5o5QDbK5cw+yuXMHsrkrWJDNXYShlChEmzscVJSIXL7SsvcBjOV6FRBtsE7b1KvCCkEUvmpTrwLfCKIQXw+R61XgksaWj4nCZTb1qqAJNndynSrcJYjCgzb1KrBVyz6+0eZOrlcB8Z/RaHMn16uCJohCuU4VRJs7uS63GNvGDCIKpUQh2dwRhHM6eURhcZs6VcgKkzuFJT2isItNnSqEg83ddLpT6Do/2pSpwlGPKMQfz3KdKuSFzR2OQYh/O5cbPvrKRHj4uTFQKqM0DB87BRo3vYKV17iiA3TocJXZrv2VV+vTTaB4lYZ63gEyimgs1xJSjdzTrnKTtpAYlz1/rEv05HLfucWXKMQ+cGicomWrQ4d2xnpUu1xfj6vasrhM/augQyvDfeWKNh2geqYxfAd+LkXPk7IaQ4err4JoPnRPiWpQWFgXxCIKpWUgIpRhHuRylZisGe+4yuWKwUThWWu5SjBReM5arhSnw+Dx8cYwenw8xFquFNN0OtuUq4S+vT3iQ10qekRhSZs6hWCisKW1PNccZrl3oZ3N3fiV2+G/74yDB15/Foa/Nd60uXtp3iY9T4EtI5tAj3ePQIynfaenV5qfnXSvMRgocnxGT9B6vA7vfXseKhXTBVjlyjB0puE/vPqD56F8065e/QaDnSjMtrnr4tPmbk4fj81dqR5weVmrzR3m6MJy8SvD73nj5CU5j1MYAYNX48UPx7DEtGLFClaG7/hh6trV2GanTp2Cf/75h8WYxEFBxXanT5+Gv//+m8XNmjWz9BXWjPYglwvgYLA42CvGc+bMYd8Nf1SKCQeJ5e0w3X333WyQWLkdDjqL8aJFi+CJJ56w9OOTQTpLbcoFMA0caAwyv3PnTjaNcYUKFcwY6zHhcYbTu3btMusqVqzI4vfee8+cX//+/S395ETWhZzfKbzpJmMg+0OHDrFxxHDsOEzoq47lQ4cOZdN9+/Zl019//bW5fJg2bNjA4mHDhpnlgRJ/ST9XSMe+jDiQOPrFYuLv8OJA4r1797a08zXguDxvp1S5kLMoxHT06FEzxv4wxv4x4fLwOlxOjHG5+TLh+uB+y/dJsZ1T/A1effjwYZbfeOONbP643XAatyMm3P44dh5uZyzH7Y4J9wOcxv0Cl/GPP/5g05hWrlxp7kdO6HekH2hjreUiuJ9jGjRoEJvGhMcDj/E4wZhfn+yOM1xO9NvFeP78+WzAZLkfn+TR4NU43adPHzYdisGrMXHvXhxI/Ny5c8xzGJPTAcdfeOGFwJZLYtX6nN8p5NcvvJ7hdQ1jdIPDxN+Bx+sgJhzPEK+PeJ3Ecrweiu3wuooJr7OBPIFwOnh1gHgXlC5d2mJzN3r+Kug2vhN0e7Ez9J7TAxpfYYzm/tKCbVCtcTvomZQOf/+52GyPohA3Yl2Ni8KycO6HQ2zwZ6x/0yMKMZ62YAbLF6xeFHJR6M/mbosDmzvMr5u2D+6Ij4U7C4jNHYlC93BbFN58882BiUIHYLK7WOVWFL744otw4cIFSz85UtemTCAUohDnw8WHIxJsyiTcFIXoQoPiDY0E5H5ypIFNmQCmYEUh5sGIQn82d26IQsy5KER++eUXSz85MtKmTMINUYhwUXjbbbcFJgodgClYUYg5F4W///47LFy40NJPMGAKVhTy+Yh5QFy0KRNwQxRizJ1UMAUqCkNuc4eMGDFCbsBGc+82TReFI7rA9W93M8uNO4V6HF8EDvy11yz3dafwl5OGuPIShRsN8bB8w+SQi8Kj5zx9Te4JcwejJVE9eLB/O+jK6ovBrP6p8H/xKFz7Qq3+o5jLysBxq+HB+Z7PfbUeSlYyDgTkpz8vwaVL/8Klz42TKIcnjOlOoXe7iBaFeXynEL/jS5cuwb///mvpxyd0p5DlsihEsYHTgYjCvL5TyEWh3Ic/8uJOIebBiMK8uFOIOReFfFkDIa/uFCIoCpcuXRr48Z1HdwoxV/1OIZ+PmAdCXtwpxKey3FoUU6CiMNA7heJTYPmJsED2hC+bOywrlFKIkZDC7d0EUYhEJcMPP5yCk1++bRGFtdsMhZMnT0OxFOMXLheF07dugfikVDhz8gykJMSEXBS6YXN35J8/mU0fYsw35zuFkWJzZ2cLlJSU5GX/48QWSJyf3EfY85AHuVxA/J4wxwsZj/n7vLxetKPCEwWP0ZbK7nt3xOs6vWzKBXKyweJ3qTDm78vytr5ssMT5OSWrqX7h2WctFxHniTG3cuLlycnJXutRqlQpFuMJWiwvXLiwGQeynPHl4r3/dW6D2C/GdlaCPHZqTcjn54gvdVF4Rc6iEOfnpF9+beD1+L2JbXkszs8RDm3ufPUrWpeJ5bj9xc/xer6fIigm5X580e8//fy+M4zzFI8Lp8c35uJxJi+z3I9P8sjmTl5Gt23ufFkJ+rLXs1tebk2I+4s4P0eU00Xh6lV+/+xm1y9e78RlxOshj8VyvH7ybYHHGV5fA1pGLUxt7vhtcCcE0tYfdqIwr/AShXiCUP2lWsId8KVkxV9MxpOd8jZYLTx3I/COglynCmU8fzS5zKZOJVp7/mji5svobtPb80eT7MFz1eMJzx9NStjUqUQ42NxV1Qybu49t6lRhteePJhts6lRhewhs7jqw3KYiAlBKFNKQNAThHBqSxj1oSBp3oCFp3IeGpAmOvBiSJpJQShSSzV3QhIXNHd8H5HKVCIdlbCcMXi3XqcJ1giiU61RC84jCdjZ1qqCFgc1dZUEUynUqEQ7HN19GlW3uNGHwarlOFcjmLjCUEoU2bVSCbO4I1TBFocKExZ1CLQzGKdTCaJxCm3IiMiGbuwhDKVFINneRD9ncuQfZ3LkD2dy5B9ncuQPZ3KmNsW3MIKJQShTSO4UE4Rx6p9A96J1Cd5hOdwpd50ebMlXg7xSiuJbrIhn5ncIcbe6eR5u7THhMsLmr2bC5pa0dNa/oCB07dgQtJs7IS9dheVqyMbxF8Qp1zLZxSUWgo8c6j7W1mZ8TfIlCnKdhc1cDOrY31qP65fryXW08vijT4Gro2NpYnmZtO0INj80dfg5t7jCu0eIqiIrS4wxjPeQ+LKJQqiciFLK5cw0mCsnmLnjI5s41yObOJcLJ5k71f5u7zWGWexf6srl7e9rzMGXscJgx9WXT5u715bshLiENylS/DOrUqcrKcMDE4pkVYdrQm6BwsbJQ9bIa8CIfzzAxLdszWGfn4lGgNboZnhu5lE1nZZWBld/obWNTYOKVMdD3zePeCxwAdqLQDZu7CgMnwPI/f4PY6Oz59mhRwasfL1EYwYNX8wFaEV+DV/PvoXXr1mbMB3ClwaudD17NB2jl7cTBd/n36ogAB68W5y0OXs0RB6/G8eL4OIaY+ODVuXkfNJDBqzHny/Xmm2+yHActxgGOxcGrcXBbjMUBqvPT5o6zefNmlvN2OFg0P344mGrWrOnVzimBDF6NyINXi+3EwavHjh0LI0eONOtw/TDm33MgBDJ4NT9+OJj4+I/y4NW8DQ5ejQnHq+PjxoXC5g6dPcRzIyY+eDWHO4ZhsjvOcCw+HMyaT4t1fglw8Go7fA1ejWPd8WXBxNvxaXk+PsmjwavLlStn3t3lg8QHgr/Bq51Sv359lvPvCAehxyQfZ/Ig8bwdH5T6xIkTLK9WrZrX/EKAd0GZMmXgqquMO3WccUs2wPfjsuDZAa3g4LhGXqKwXJ07YFhdDW6b9zPENXkWSifqJ6EiGjzX83LoNHgGdC2vwUsLP4WyZTMFUZgEmWXLwjPtjJPILR5RuOj9F+Gr93Gk+jj46N5E10Uht7mbP7avaXP3yN1XmzZ37/1fCdPmrvbAVyw2d1PWbWB5tihMgrK3jYHyUt88sekItrnDEx8/CH2JQrSSevdd4/sTtwfelW7UqJGlr0jHThRijD/Evv/++xxFIR8wHdP+/cZg6zjoacB2XX7A9PDDD7P44sWL5jZG+Mj9P/74I7zyyisWUYgnLn7xEEUhtpf7yZG6NmUCsij87rvvoHlz48kF7lt8ue69916Wi44mKDBE4fLrr7+ygWRx2QMaPDYImzsUU3xgaN4vb8dF4W+//camcRBm7sSB321ADheIH5s7nB+/4KxZs8Y8XvnFCoX+l19+yWJZFOLncD1wH7n66qtZHX633LXIMQHY3OHx8/PPP7NpFIO8r8zMTFPc4nbHNvikZubMmRZRiMfP+vXrAxKFTm3u7EQhwi/6+J3hNsXERaF8nOH3jXmojm8uCrFfPO9gjMt1/fXXe4lCzPE7W716NbvhI9oEfvDBByzHwaH/97//WfoJBkzBikLcj9FiEwdsxs/zfdwxfmzunOKWKBSFPJ7j8Jwn9+US3gW+bO4uTCgPH46oB/tGZT/q5aIQ4/jWr0JyrAZLDp6Gclq2KMQ6X3cKV3xpCAcuCpFjO17T80RYNtD9O4Xc5m7ZpGybu2GyzV2hWNCi+kLN/i/b2tyxXLpTOKW3sfNyeMI4ku8U4qsG/mzu+LSY89HV6U5htijkAsCXKMTvWvxHLm+H8Hk4wsGdQkS8C8znz7cvghczFLKiKOTbVba5w2UPpc0dL8PEX3/BO4UY8zuFvJ7H3OYObcQw5zZ3fB2cEMydQvzu8KLAn8rINndYzm3uEEy8rbgeTgjkTiEmbrvl62KFMYpCvjy4Ppj4nUIklDZ32C+3uUMw8Vi+U4j7AbaXRSGmDz/8MCBR6O9OIdrS4TGC+5QsCvkPJb5/yjZ3vC2P8+pOofjEwc7mDr87fi7HdcNUqVIl2LTJc00X5in345M8ulPIf9zgj5dIuFPIt1luzwMBkD2Rk81danIco3BS9svVFlHY6gVdHJyDuBj9IvHdjz5F4ZOrDzIR0aVJaVbOReHmzVOgfIP2cPo74zGv26IwoUhxOK0vH7O5GzwBfjRt7n6FM0cPsHjIsp8Fm7tz8PCNTSC2UBKcPXWG2dxhOReFj3+4X1+Pn9j8xH54wjilUviLQgStq7jNHbfZQpscHmPOYzzpiuVo+4O/6DHmllQBWXWFCw5s7sTvCXO8E4AXDLkcc7zLwWO8WyPWi9uC23k5woHNHd9mPBa3mbgMvF9ehhc8HuMjMB5jOx47JauJLgr3W8tFxHlizAUdL8e7f+Ly8rZ4nhPL7do4Ib5svPFPVJs6Ds6T24hhzI8D8V1j3i+eZ3mMdzfE5eL2VOL8HLFXF4WX5ywKcX5iv7jt+b7H+8V9QP6e8A4Rj/l6yfNzxBJnNnd2/WKO25PHYjluf4zxpgZO8+MMy/AcJX7HTmA2d37+DCMvg3gccEHIp8XjAnN+nMnfdUDHN9rc9bApF/DVr7zsmPNzPH5f/Pi2O1/hdyz34xO0ucMxKeVyARTv4vx5jOdLu355ma9YnIcjuM2dnx99TpG/L/66Ay/zdfzI5wExttNqQbOd5TYVoUIXhQcOHLCW++D7ny9aypxiJwrzCi9RSH80KTjQH01cg/5o4hL0RxPXoD+auAT90URd7P5oEikoJQppSBqCcA4NSeMeNCSNO9CQNO5DQ9KohzwkTSShlCjEE/LN6sJs7mzKVeKGBTdYypSD7wNyuUqEwzKKNndynSqINndynUpoHlHY1qZOFTSPKGxoU6cKos2dXKcS4XB882VEmzu5ThU0YfBquU4h7tlyj6UsKIxtYwYRhVKi0KaNSshDZKhIboY1IcIXsrlzD+UfH2th9PjYppyITMjmLsJQShQO1MsfU5frP7veUqYa7de0t5QpB98H5HKVCIdlvFEQhXKdKtwjiEK5TjGKvVLMUqYUmkcUXmVTpwr1BFEo1xGBwc9BOKSTXKcKmiAK5TpViBFEoVyXW4xtYwYRhVKikN4pJAjn0DuFBQt6p7BgQu8UBsefHlG4yaYut8jvFIbK5q5ig7bMDu7yKsYwF23aXwVNqxSGRi3aQdvGhhOKpsVDZeEi0KFDRyhZKA4ub9UeiiZa5+kPX6KQbO6IkEH/PnYN+vdxAYL+fVywoH8fuwYThS2t5blG/vcx2sLYiZyJa3bBlI37YeCDI1guOprIbTk4eDWPH5q6kuWTduyFKD3/dsH9bLp7zZrQ/7XVLJ639TQ82dFoXyi1BtSLjoKTm15m0y0qWefvDztR2Om1TyBJqwwDO9WCBSvehsa9noFiCQmwblxPKJF1HZRNjoZzG4bBXW/thkIxReH+tlVhzfoFUK3rMCinFYUNE2+D4vWugvOecQqvZgN9t4L2NYwxhzheojACBq/G8ZB27NgBN998M7PY+eSTT5jzzQsvvAAHDx5kbXBkfO60gGU//fQTi3HU9ffff5+Nt4Sfa9CgATRp0oTFESeYHQxejYOScmcSHJCVW/7hgLf4ndSpU4flOHbYG2+8wQYVrly5MhugFcuxbdOmTc2BgrFsypQpln584mDwahxMlQ9mjE4F3I1k9+7d5gCqWI+DHONy8uXG+NNPP4XSpUuzQXHPnz/P2uL7oIEOZuxv8GocNw37xe8Bx2z87LPPoHv37swKjh97aNnJvzN0YhBt7ng5f/yC48nx+cl9+cLJ4NVug+OZ4XJ26NDBa18Rz3WY+PrhtuNuE7xc3Gbt27dnMR83Lb/wN3g1bhdcTtxOuM2OHzfGsJUHf+brjdv41VdfZTHuh3iM4P6B+wmW4TkJHU+45Z0T/A1eHSr4th0yZAhzOsFzqbi9cdBsvt5nzpyBLVu2sBidXrAcB0Xm3x0OpI0xDkAt95NnOBi8evjw4aZrky/wPIpOKzhuJa5T48aNWTn/bvC8ieXly5dng4n7m5+Mv8Gr8fqF88frGV7XMMZtg/sWdxvB6yBeD/EchddHvE5iOZbh9RNj3Gbjxo1j42riPPi2dMKsbdnvFIrb9v777zddcXKBdwFe7LldEQdF4Zr1G2Dbtm3w6vvrLDZ3Q9Hmbq69zV2X8tmiUIsrDGNbRJuiMLVEBkxZMcfTT00mCqv1Gg2lhnzAxOMTH59idW6JwmBt7qba2NyVK8A2d5j8OZrI7dAmjdtSRZyjiQN8OZp8++237MLny9EEReEPP/xgzoeLFzzRc8svt8DEL7borMCXEcHtjDnWY5Jt7nA98ASIadmyZebnHnroIUs/ORKAzR1e2HGwW76cPEdRiMIbY182d6KPLv4olp0acsSBzZ3bcB9dTPwHBT/XcfH+119/mc4OmLg7BtajCwTGuK7o6MFjfEok95WnBGBzh4k7mqCnOm+DF2J+bkGbO/7DFPdJHBAYE/7phgtBtLm77jp0trL2Z4sDmzu3wcGan3rqKRZjEt0xcF3x3Iyi8MKFC6xc9KvG9ebv5uI25udgjLmFnapg4o4mKKZwXdDRBF2S+I8c7miCMZ5zcB9B/SK6tKBI439SRAs/uZ8c8WNzx69fuB24/Sf6WmPifeJ1EBOeG/H6yM+fuC14u3vuuYfVo8jF9eT+8Y74Jjvmzid4MwET2hJa2jvDu8DO5g5Bm6AFCxZAPc9OiVgcTXzY3JmiMCkdmkdHmaKQ0fp+aMhiQxRiWamhy5gofPO4cUJ3SxSSzV3uIFHoEAd3Cn2JQgSTL1Eo29yJd7TEefjFwZ1CTHaiULa5w+TL5g7z+fPnszzUNne+RKFocyeKQoTb3PFtwd0BuPhwQn7cKcxJFMp3zXguW6bxdbXbZvmFvzuFTkQhItvc8XXF6xfm6OaB+wuWr1y50lWbu1CAxxyKIrzTiUkUhXi3Hq3QcF1kyzTRCo1vY7R646+H5euIEw7uFGLiolD0W8Yk29zhuvL9g39f11xzDVtXvp9g3KJFC0s/OeHvTqFbohCn8brKbe4CQbxT6EQUiq8H5uCIkj2BXyS3t5Jp07YtPPvc814ztYjCW1EE1oNG5aJg5p1XW0ThnnNnWM5FYfXqqXD3xHUQw+ZniMIaN02AxLSycIXez+7pvVg7t0Thre8chRStFnRtUAJWb1sFrfuNg1gtGrZNHwClq93E3jX83xcvw8Mrj+miNBYeufoyWPH+q1C/1yNQGUXjEOOA5KLw4YdxJ+sE1zY0bII4PGEcCaIQ+fXXX6F58+bsFjcatOPjpsGDB5u/2vBA5OuMwoYLP7wjg4b0+EsOP4e3+nEfwzgQn9mwwIEo/P3339mdHIzxUQI+6sFjCr8PvDDjRQtj/LX40ksvsRMiWk1deeWV5t0ArOdeyRg/++yzln584kAU4mMNfiLGExk+3sAY+8f+MMb6559/ni0nluFy42MLjPn63HbbbawtnvhwveV+csKfKOT94iMcPLlhjEIZ735hwjtFeHeS94uP53mM+ycXuLgt+PfN5yf35Yv8EIX8u8UfCOK+golvMyzj2wxzvq5YntM2k/vKS/yJQtwufF3Hjx9vriseB3yfxJx7WeO2fuyxx9gPWr6umPPPbd++nZ2jArkrkx+iEMFz6GuvvQY9e/Zk68t/oOO64jl00aJFXueUjz76iJXj+mJb8bvDH08Y4zlF7ifPcCAK8f1Nfo7DxPfRzZs3s3W877772DrjuuNTFHGfx/0dn3ai9zGWv/jii0z88/k5xZ8o5N8xXs/wuoYxXufwesefROA+hucbPEdh4q9Y4XUTr594HcXP4XWV78uB/IFNFIXitr3hhhvM6wXCbyjgjQhehjce5Pl5sBSEnG9PfAuz7q9hKbdj3ppPXROFeQVPGAdykSHCHPqjiWvQH00KEPRHk4IF/dHENUL+R5NIQilRSEPSEIRzaEiaggUNSVMwoSFpgiMvhqSJJJQShWhzd5O6DFg/wFKmGszmzqZcKfg+IJerRDgsY1th8Gq5ThWuFUShXKcYGQ9kWMqUQhNs7uQ6VRBt7uQ6IjD4OQht7uQ6VdCEwavlOlWIFgavlutyi7FtzCCiUEoU2rRRiXx96dgh/IVcomBANnfuQTZ37kB3CgsWZHMXYSglCsnmLmjCwuaOcI300emWMqUgmztXyZqeZSlTinCxuePXIbmcCAwtDGzudHrv7m0pCwpj/zGDiEIpUUjvFBJEZEHvFBYs6J3CgkU4vFMYCuR3Cn0NEVK5ek3IqlKV1WNcNM2wflMZpURhOWsbgiDCmFIeUYjvC8t1RORxr0cUqv6v2QYa2zct5URgvOMRhXNs6iKZW1meXeDP5m7Qg4/b2NwVhR3jrvJqv2XbCehQXZ9fp8FmWaOHsp99n7x4GDKTjPiDlW9As1tHQXohDR5/Y6ml79xiJwo7jTds7gZ1Rpu7t6Bxz6eheAhcCbxEYYSMU0j4BgcB5s4Z6DoSDu+iEMGTH+MU5hc4/hpaaAXsChFBuDVOYfXq1dk4iei+IV+jgqa/znKbcgVA20E+uHg44G+cQre55ZZb4PPPP2djGn7//fdsH0FHFrldHuBdEJDN3Yf7oXz1JjD0MmPw6qRYDUol4mc6maIQfQdLpaeYonDa3nPw5rc7mCh8tf/l8HyvK/TycjC4TWzIRaGtzd1VsZbPBosoCiPB5o7IGUx8UFB0yJD3OyJCCcEPSlVBRwa8M8r3bfQexgF75XYRjUs2d9z+Ee3rMPFBlyMdTOhIgzHuPydOnMjJVSP/uWhTFkIw4WDj4nHWrVs3S7s8wLsAR8KW/zF77Q29mGp9bMQT8J/BD0CVatVYOd4prNzwSeYEEhvfAlY/Up7Z04mikM8DRWFUUnG4KrUIzDqxC6oVNwzYX+yNVjHl4T8tQ3+n8NiOCSyfN7oXjLu9jR6XgQfbWT8bLDxhHFVW4Z2ecAVMJAoLIDiOYpRNeQQiikJ0X0CHoyFDhljaRTJxz8eBVshaHiiyKERrNLlNronTYTdm1AMTF4XoxoKOG/nqrOKHxD/ydtkwKScKc7S5a9OG2dyJyt54fBwFv/6wFuL64UWxCVQqhvX2opDH/E7h9P+0gA3bV8DV905hVnehFoW3vC3a3K2GNneM81jsuQtPGNPj48gHreq4rR9aL6FHuNyGiDwK0uNjPO+jEKxTp44pCrmVV0HBrcfHKITw++MX/0AtIHNE4cfHw4cP97KdRFGI34PcThXy+vExeilza7pjx46x7wZf25Db5QGWgpDQaOR6GHWttdwkqzUc/CS0ojCv8BKFYTBOIUEQgUM2dwWLsLC5m6bT2aacCIyK4WFz5zpkcxcaLKKQhqQhiMiChqQpWNCQNAULGpIm8lBKFO7VyxcRBBExfCOIwjU29URkcZcgCr+zqVeB/Vr2dehnm3rCOZoweLVcF8kY+48ZRBRKiUKbNipBNneEapDNnXuQzZ070J3CgkU4DC1GNncBoJQoHKSXj1CX7p93t5SpRru17SxlRC7g+6lcrhI3CqJQrlOFewVRKNephOYRhX1s6hSi0huVLGVKUV8QhXKdSoTD8R0OaIIolOtUIUYQhXJdbjH2HzOIKJQSha9Y2xBEniO6bzxiU68KL3pEIY4DGGtTrwJjBVGYaVOvAq9pbHgSJgpftKknnPOYIArvsqlXAfEPJo/a1BPOudUjCu+0qVOF/3hE4Q02dbklleXZBWRz5w4WUUg2d4Qq1NfJsClXiYYeUXijTZ0qhIvNXV+PKGxkU0c4h2zuChbhYHM3zyMKJ9vU5RbZ5q5s2bI529w95MTmrioU1vOtq8f4HKfQ2+ZuOrO5K5YHNnedmc1dlmlz14hs7pRn586dbFtWrVqVOeqgQ47chggAfJVhqU15LkBHgsWLF7P4f//7H6xcudLSJrdkXXDnncLHH38c9u3bx2IcGw3Hk0xISLC0yw1ujVOIziC4bzdt2hQaNWpkOW8FS5ULar5TiOuL643r7/Y6hwK3xilEmztcb7zeXnHFFeZg1q6g8DiFaHN36NAhqFevHhw+fNhSrxpujVOI58affvrJUu4Gs7bl/E4hnu/wvIfx3r17YcSIEZY2NngXoKNJmnQnEEXhmBmzYc57C2DS2t3eojA6Fg681g2iUjLh0MGvTLH39qIZtqKw5PUz4T3P4NXvPtAaXr0DBWX9PHE02XzCGFR46cReMPE/XfW4dsgdTZIOJFnqCedUrFiRfZfvvfcem37ppZcsbYgAwHfLXPplyR0ZMN6/f7+lPhjK7StnKcsNmFq3RktLDXbv3g0//vgjVK5c2dIuN8R9FeeKjWWLFi1YjgOfY86/U7eosK+CpUwF/vjjD5a3atWKrTOKJbmNStyw+wbQhlvLA0V0NBGnXaGnzlSbcgXAxB1NUBSqvr1nbJ9hKcsNu3btMo9pPPe4ud6jPx1tKRM5d+6c5TiT29jgXeCGzV3355ZDVc3qaEI2d0SgkCh0GRdtsERRiLjp4Rp9RbSlLDdg4qIQrdpcNZh3yeYu1KIwuoU736XbyBerV155xdJGJUJhcydOu4KLx7fbYBJFId58Kgg2d6IoPH36NPzzzz+WNrkl4XDOTz2CFoVoc+fL5Lw12tw968Pm7uQ6iOs3F5jNXZshUCvdaCOLQh5zm7s3TJu7qWRzR9iCt96vvPJK9sgPLYDCZRgQZXHx8TGKmJkzZzIrJtw2ycnJlja5xa3Hx/geGLfWwoTLWalSJUu73ODW42N8VxuXC3+MHz16lC1nhw4dLO1yi6qPj3F9cb1x/TFdvHjR0kYl3Hp8LJ7LMOcWma6g8OPjRx99lAmU5s2bw5EjR+C3336ztFEJtx4f4+Pbs2fPshhFIU6j1pLb5QZ/j4///fdfU4vgedDhsEqWgpCANnejr7WWm1QmmzuCCDn46LirTblisD+anLWWq0RY2NydDo9xCsMBsrkrQFQMD5s79keTltbyXHOY5TYVEYBSopBs7gjCOZ08ohAfz8p1qhAuNnclPaJQ9X9Jq850Gry6QBEONnd/ekThJpu63EI2d6HBIgrR5u59gshnDmjZ++lPNvWqsEIYvHqJTb0KiDZ3a23qVeBfjS0fE4XLbOoJ58g2d3K9CojHN9rcyfWEczRh8Gq5ThUKCYNXy3W5xdh/zCCiUEoU2rRRCbK5I1SDbO7cIxweH5PNHaEaZHMXYZAodA6JQkI1SBS6B4lCdyBRWLAgURhhKCUKyeaOUAHxBXSyuQuOMWFgc0e4h2hzp6r1WSch/q9NPeGc2zyiUFVLQ+S+/La5q1qN1VepUQuKpqVb2qiGUqKQbO4IVUAbLNVt7hp4RGFfmzpV4DZ3YfBPbsIF7vGIwio2dSrRUFP/+A4H3vaIwtk2daowNwQ2d7exPLugbdu2UKxYMUtDdDSZsHoXXNXpWm+bu60XYN26TdCwUvbYhvUeMoaVObB7u163GLSanWHR9OdYWbMxn7DBrTFOKX8ZbFz3CdRKT4LP9h+19BksdqKwcMUGsEHvs0pqIvQeMRl2fbbW8jk38BKFndR/fKwy+FgpNTXVjOV6IkBG6wy0Kc8FuD3cHJ1fJKtPlvjic64pVaoUW04cJJcPYu0W8VfHKzsmXCjA79Eti8BwpN9T/Vy7A8fPZa6f0/Cp1ACbcgUoV66c++sbKnRhvWrNKlcci3Cd+QD1mLv5HcxaqIvCy6zlHOxL3NdKlixpaePFuyz3LsytzZ0WFQUH9x+CV+bsYXV3dfBcLHRRiHls0epwe8YQJgonXVcaVh4wHCqWzuwPjW4ZaV24ILEThWRzF36Qo4nLhMjmzm1xGAqbOxy81c3ldMvmLhxANxi8Mxqq7R0OhMLmDpOr32WY2NzhOru63iEgFDZ3mHbs2GFpk1vyzeaum2xzV9Vqcxff7jUopGXfKfQWhVFwaOlwKF/1v5CaZLyHs3vrZJbPGZ93ovDYznywuStHNnfBQKLQZeJ1PP7kwcIvauho8ssvv7hrc9fMHWs2TKIodNP7mA1s64LNXTggikJ0rsHtPWTIEEu7SIbZ3OF7rjZ1gSCLwi5dulja5Bq0uXPp+HYbTFwUoqvHr7/+qrTNXdIf7tzQCaUoTDyc8/cXtCgMxuYuJqEwXF00CT479jOrk+8UImmeO4XjumZAr0m7IVWrDjc2L51nopBs7sIPsrlzmRDa3KGlktwmt7htc4fvKGKOyxgd7Y7gdMvmLhzA8z5u49q1a7MLOcZ//vmnpV0kEwqbO0z8ou0KYWBzhzGKQrS5w+9BbqcKobS5k9vklpDb3AV6skwrnmHkpctCvJ6XLVcOktKMZ9b4/gAiisLoGENwpiUaf2hh9XqeV6IQ4X3GpxSFcqVLWOrdwEsUhsGQNEQBgmzuXCMsbO4I1yCbuwJERbK5izh8icK8wCIKyeaOIJxDNneEapDNXcGCbO4iD6VEIdncESpANnfuEQ42d4R7kM1dwUIjm7uIQylRaNNGJcjRhFANcjRxD3I0cQe6U1iwIEeTCINEoXNIFBKqQaLQPUgUugOJwoIFicIIQylRSDZ3hAqQzZ17hIPN3as6iR5R+KJNvSpkekTh0zZ1qkA2d+7QSIjvt6lXBbK5izyUEoX0RxOCcA790cQ9SnpEYRebOlVo5RGFQ23qVIH+aOI+P9qUqQL90cQAbe6KFy9uaWja3HX2trlDlh7+zox/W24MZjrojW1GWaNbIEvPzx7ZBVvXb7fM1473h9WF+HJ1WXzq+Fewdu1ayCqiwdSVn8KVVTXYoU+/+RS6kWjQpfujEBNtfC65XB3YuHYb1C2eDJ98eRj2vG0VhWhz9/HabJu7nZ8aNndvrDsImzduZfHLq4/Akf2LWbxy3Sfw5vCboFBaJmxbuxGur1wcKrW8Htav+xQGNypn2Oat3Q5VinoPIOklCsnmzpbmzZtD+/btWVyjRg0zxrxJkyZmzG21eH358uXNGAU3j8X5ETkwSvNrc1epUiWv7dGyZUsz5paDGGM7HmMeFxdnxo0aNTJjcX5OybpRF4WLrOUi4jwx5gPh2u0rmLdp04bFzZo18yrnj1cDXcb4DrooXGYtF8F54nmVx9xGVF52zHFIMB7Xq1fPaxnr1jXOiXg8BLScC3VReFPOj49x+fg8sR+xX1wOHvMhy3h91apVzRjXi8fi/BwxTheF//H/+JjPE7eXuIy4PXksluP2Fz+H+0dAyyXRb2Q/v3fgcP7icYHHAY/x+OAx5r6OM8zFcj4/RziwuUNDAHH+OKgxj8Xjm7fnsXh8N2zY0GseYnu/vKnTw6ZcAO3Y7OYv91unTh0z5p91EvvFoc2d3fxzup6J5ZmZmV7zEq9nTmE2d3Wsy5Oenh7wvBjvsNy78Prrr8/B5m6hl82dFlcZBtXPhIFFjHa+ROEHT3aEotWNz/SZugMOfL8PahWNg6Wbd8H8x6+Ht6feC1qp5tBRM0Th16cuwIEpfeDU4mHmMkyd8KwZj5//EcuLlhrGROH6k1/Aot3zWNkHs+6Hej0fsRWFW+xs7m5sCh1YfRrMvjMF7oiP1eMboNY1w6CCXn7n6I9g4IS32OcW710Pn+9FV5RYmH/hb9h03DO/Sb29+hFFYdJ+d0ZFjzQwbd1qCHFMOLo/xjjaPyY8KeBJCNOWLVtY3eDBg83vdfny5SwWnRY2b95s6YeQQJu7STblApgGDhzI4p07d5rfeYUKFcwY6zHhHXmcFkftl11o8H1QPFHK/eREub0529zddNNNLD906BATJCiWMG3cuJGVDx06lE337duXTX/99dfm8mHasGEDi4cNG8amO3c2xlM9fPiwpS9fxB3wb3N35MgRs18UXJj4O7yTJ0+G3r2Nc4fYDoUYpmnTppntMOEF8ejRowHbg1XYW8FSJoIJ58tj7A9j7B8TF4aYcDkxxuXGhDGuDyYuXMV2Tmm6p6mlTIRvF3TEwITbDadxO2LC7Y8XQtzOWI7bHRPuBziN+wVvh/sLCq1A98nrd10P2qPWcpH+/fuzfgYNGsSmMeHxwGM8TjDmT7LsjjNMOM3nycsdgTZ3U2zKBTDdddddLP7iiy/M+eN3gmnu3LlsetSoUWa7PXv2mO3wLr7YDkGHG7kfn+Aj5FU25QKYuFjFAa/RmQN/hGDi79GNGTOGTXMxjYOp80GiO3XqBO+++y6Lx44d67W/OuWN7W9YykT4j5G///6bDUqNMbrTYOLvwIvXqX/++QdOnTrFyrt27WouD+6HZcuWZdN4Uy6QJxCjPh1lxpMmTWL5G2+8weZ12WWXWdo7xLvA1ubu+p62NndXPzqP/bLYd84QgTmJwoVffwZaYhr8/vPP8LPOyuF1YM+p3yFRF2GyKCw15APmfOJLFO45uInlXBRivHXjFJbPnuxbFB7bOZHlXjZ3A9pBHVafDLMHpELbOBxYuzHUGjAKiuvlN4yYBw9NM3bCqevWw7erR+hxDIw5cBGO7PDM7xXfojCqPNnc2YGJRGE+4MDmDpPdxSq3ohDBi6XcT074s7lzWxRijCd3uZ8cKan5tbkLhSjk7ZwS3TLn7xJTfovC2Nvxx7i1nOO2KNy7dy/b3nw/ckL8C/F+be7yXRTi8Z1sUy6AyU1RWKhQIZg9e7alH5/ge8KFbcoFMLkpChctWmQuv1OS/0i2lIm4IQp5uwULFrDpQEVh0uHsm04hEYV4W75Dhw5yA8a0adPZDoSKlpfN2rSJPVK4dtKXcLmWLQprDjIUNncqQVFYrs4doMUVhrHNxRNUFKxZ8LwhCmt0ciwKu45fznJRFL6y9WOWT7r/Wp+icOaxz1k+uldLmDn2NtAy20O7qKpwTy29PikTbo1KgHGt9F//DR6HUlH6fIppMHzuu9DjIePkvHb9i7D4+EegRcfDvovLYcaRz4y+e2c/Tkd4wphs7uzBRKIwH3Bgc4fJ7mKVW1GIJ75ARaE/mzu3RWGfPn0CdnRyYnOngiisciHnx8eY8lsUtjud8+Njt0UhppUrVwYkCp3Y3OW7KHRgc4fJTVGI20K0v/VLK407Z/gEk5uiEI9tvvxO8Wdz56Yo5O0CFYWizV1OopCP5iCK9zvuuMMyPw/ZE4GeFEukGUo6OjoByhRLhjJlyjLRGK2XZep5yTRDEBUvgu+FRUFmySKQXNxoExsTBWX0PDE+GpKKFIcSxdIhQW9brHAcROnzK1s8GUpnlmFt42O5KIxh02nJxq9KbptXonQplnPB6ksUim3ik4tC2Qzj/cnUkvoyZZZmcXIxvc8SxnxLli4LKYnGeyD8c9ExsXpcholWsVyEJ4zlu64Eka+QzZ1rhIXN3ekwGJJmYxgNSUM2d8Gjb2/PHxrUpSLZ3EUc9O9jgghT6N/H7kH/PnYH+vex+9C/j4MjL/59HEkoJQpnWdsQRJ5zqxC/blOvCpM9ohDfj4qzqVeBeYIorGhTrwL4GDHeIwr9/LkoX0nziMLnbepUYZggCofb1KvAzUI80aZeBdoI8bU29arQ2iMK29nUqUJnjyhsalOXW4z3zW0qIgClRKFNG5UgRxNCNcjRxD2Uf3yshdHjY5tyIjIhR5MIg0Shc0gUEqpBotA9SBS6A4nCggWJwghDKVG4Vy9/mSAIR6wQROEYm3oV+EYQhTNt6lXgksaWj4lCHGRbrlcFzSMKceBluU4V7hJE4Vc29SqwWcu+Dp2xqVeBD7TsZUyzqVcFTRCFcp0qFBJEoVyXW4xtYwYRhVKikP5oQhDOoT+auAf90cQd6I8m7kN/NAmOvPijiWo2d+d/P2mWP/qO8fnvD+6AhCpNYe3ajVArw6ibufu82a7PiCmw87O1MHvkgxZR6IbNnTi/EUv3wRefG21FvEQh2dzlGWjrg+Mb8hjzokWL2loRoT2SaDmEY8DxWCzn8yPylvyyueNjjzkhP2zuxPk5Ih9s7sQ2jsgHm7umTZsGtoxa/tjcBUw+2dzVrl3b0o9P3tTy3OZOnIcj8tDmzm4eTsk3m7txSzZA9wVd4LoxXeHGt3pbbO4GpRrtfIlCw+auNSu7ceoO2P/dXqiNNnebdsL8x7tbHE0OnboA+6f0hs/HPwANMuMgudvTMG3uSvb5Kfd5+o6Jh+X3GTvEzGPnWD53eEeYeG8XPa4DO//OFmacgGzuOtnb3JWo3Qr2HzgAi++Oh5UvNIOUFo9BWaEPRBSFSfvI5i6vaNGiBfvecbBSnMbBS/l2wEFNcXBTjPGkiwkHP8Vp/LWFCS9yOM3b4cmSf57IW/La5g7jzz4zBqN3Stz+OL8XDTcHr65VqxasXr3abOeUCl9WsJSJYHJ78OqaNWta+smJpl/krc0dpkAHr2Y2d35EoduDV+P3aHejxidoc4djkcrlApjcHLyaz1Puxydoc/eRTbkAJjcHr8Y8kG2NTP8k53ft3Ry8esWKFeZxL/eTEy9/+rIZ5zR4dYB4F6B6xS9ULBs170PoNr4TdHuxM/Se0wMaXdGClWe1Mk5o371nuBr4EoV/XvgR9i59DLSoJJjarTRkZHSAxY/Vg7F9O7J2sijkjiafj+8O0/6vCUxaOxs69sHBq7koLAMnv90PxVKMX15cFCJjbsP6TFh9mn0vXutx7PPXWb5+1iMw9nYUqZnw0uN3Qm1WnwRbXmwNrZnNXUNocP8kKKaXd39sLjw01di53tr6Oaw6+aU5v6ueXgln142GGKEPhCc27eeiQbgHicIIoq5NmUAoRCESiPexP8szxE1RiHFMTAx8++23ln5ypIFNmQAmt0VhoI4mzJNbLhNwWxTu27ePHec4Lfflk5E2ZRJui8KMjAyz3C0wuSkK7777bnj//fct/QQDJrdFIV9+x1y0KRNwWxTifAJexm+y45CIQl82d3hLudsHHaHbwK5w/dvdzPJQ29yhKBwy/0t4tGM9yPIShcbnfzll7ByiKJw5xrCvOwXZO7FZ54LN3S60ufPM79FK6KRSBzrVNx4JcXjCmGzu8g4ShZFDftjc4XQgojCvbe4aNGhgirdAIJs7qyjEFOidwvywueN2knI/PskHmzs+T7kfn+SDzR3m3C7VKXlpc4eiMDdWfOrZ3BU1Ho2iLV1msSTIzCwDZcqUYTZ3pfW8RFHDBq9Y4UKAArB0iSLMRg7boM1dpp4bNnfFoHh6GhTS26anGDZ3aJtXsij+iktgd+JiE4uweaEojC2UwubBlyMtw7CoSy+cAPHJqVCmVDGffzThn+PtME4toS9T6QwWJxXLhDLFPfZ5GWUgJcG4G8k/hzZ3GKfGR0FaqdJ6bHxOhCeMw2FIGoJQDbK5cwmyuXMNsrlziXCyuStpU6cQZHOnGX8QkMvs8CUK8wKLKFT9ACAIlWjpEYXNbOpUoaxHFNa0qVOJ5h5R2NqmThV6ekThbTZ1qjDSIwr93BnOd8roFLYpV4lKmuFWtMWmThXWeUShysu4wyMKF9jU5ZYrWW5TEQEoJQpnW9sQBOEDbnOHFneq2ty9JwxJgxc5uV4FVmhkc+cWQ4UhaR6zqVeBW4RY1e3dVoi72dSrQiuPKGxrU6cKnTyisIlNXW5JYrlNRQSglCi0aaMS5GhCqAY5mriH8o+PtTB6fGxTTkQm5GgSYZAodA6JQkI1SBS6B4lCdyBRWLAgURhhKCUK0ebuJYIgCMKCJtjcyXWEc0Sbu9M29Sog29zJ9YRzRJs7uS63GNvGDCIKpUQh2dwRBEHYEw42d4T7qGxzFw6oYHN3tWRz99GoXnoeAz/uGs+m716cbTc3bs400ApnQKI0r0tnD8CaNWtgx/tPQYJU16iGYfvC6fvmcaiShoNJa5BYqjs8eVNDGDhtI9zWWIM9+jw2zjTGUGrd9m6o4fnreGKJSrB5zSY4f3qHRRQWrtQQPl6zHaoURZu7KbDDtLn7CjZtNMYwQpu7b7jN3dpsm7utazbADVWKQ1bLG2Dduk9hSCPDQqncgDegvvSPNC9R2Fn9x8dEeHPllVeyHI9dHuPwUjzGceZ4jDkfdw7jqKgoM+YWbLwtQeQJY3VReF/ePz7G/Vw8LvjIFuL+z2N0FuExWrCJnxNjbl2Wb+Dd1oE25QI4HqG4zK1bG25jGKMtKI95ex6jzR2P0b7P7rtzxEzNr81dKMDlbN68uRnzV7vs1hXHs+QxWiKK64o2djzGsXHlfvKSWYtmednc8eXEc7m4Xo55m+XehQ8++KB5oeCMX7EdHnlnLAx5/Wl49K3XTFG4dtObEJ1aETZ9YgzIuPvMNihVuTbUbVgdsipkQuWeI6BbnWoQk1AYGjasz9pcWm4M1qlpVaHPFZUgs3JNaFi3OiQUKQ67Fz4DWnQc8zdM0QxROKaD4anYf/RCQxQ+N8FcrqHLfmZ5v9L3MFFYrmo1uHfih6xswFMrLKJw1vHjLH/vqS7w/ht3g1aiNfTT+34MB9NMKA0vt0qE2b3iQavxMFTO6AmXl9H09V4FvR+bxz63efc8+Oj7HfoyxsPOi0dZ2YaJi3MWhTR4NRFC+PugOHApJjx2nAyEzL2eebv69euzeOrUqWx6ypQplr4IIlT4G7w6FFxzzTWOB0LGNHLkSDYQMiYuBv766y84c+YMizt37mweT/lGEINXy4NSOx28evTo0WadIxwMXh0KNm/ezJYT3wXGwaQx4eDSWIfvrA8ePJjFOMg1JhTB+AMA07Jly1jdU089xab5foJJ7icvcTp4dYB4FwRic9f1lQ+gWouRkFb6PhjTMgYW3Z0ODy01RpRfOOO5bO/jT96GjIwsePcWURRqMO2B1rpgTIGMDveydpunDGDlaO3zz8GxTBS+sHEDxNYZAGPvvMpLFC45eRKuLFXSM6++5p3CV+fOZPmAAS9YNpgbNnfHVw3X42gYve8iDHj7gB53y1EUks0dEUpIFBIRgR+bu1DgtihMS0sLyCElv8CUr6Iwn3BTFGKMd0tPnDhh6SdPUc3mLq1Oe1i+8TPQktLh0qWVUDQ51lYUbtpk2CYh2aLwBmhcToPx/TtCuU6DTVFY+/aJRruD45go1LTL4OTOaVBKL5PvFJYatpy5p4iicNBrxo464IXV5sbj2NrcaVXgXm5zp3ls7ho+rvdn2Nw9JtncLUabu+h42HdxGbujGhV1LTQo7n1nlSeM6U4hEUpIFBKRQKTcKZT7yHPoTqFP3BSFfFtjkvvJS5zeKeSjOcyZM8csc2Rzh8+h5UfHCJbFJ8Z5EIZhiCoGXy15GNDCbvCaS+wdQS9RGFsJfvliKVRvdyOcP/8jxOrll/76TY/Pw3MtjPealuz8ASbNnMVE4dLjv0PhSo3g/JnvdVFo3CnENs/3bcPybFGYzuax5WV+IjFE4WvrNkBsoST46fxPcHHvXMsGi08uCj+e/xniYqKg/f2vw697jR3i1S3/g59OHGTxfct+hd/XPcXirV//DA/1bgQx8Qnws778yQkxUKpaYzivnyxKFEHrPpxvzncKU8qRKCRCC3q+Yo4nMR6L5YULFzZjzHFarOcxfl4uJ4iQo4uYdl3zXhTifi4eF/wdM/m4wDw5OdmMUVSIn7OL8w0ctPp6m3KBxMREr2XGO5w8jo2NNWPenseoA3hcpEgR2+/OER/p1LcpDzG4nPydSYxjYvCpoP264jvZPMabYuK64r4gzy+/mDVHF4VXZE/z5ZSvBdzCWNxOhQpxDSOwg+XWjlQmrWwVKJliLZdR6t/HZHNHEARhTzjY3IULZHNXcCCbu8BQShSSzR1BEIQ9RcPA5i4cEG3uJtvUq0BbIVbZ5i4cuCYENneJLLepiACUEoUd9fLe6jJo7SBLmWr0fK+npYyIXEr9p5SlTDVib4q1lKlIxv0ZljKl0DyiEB8pynUK0XZiW0uZcvDrkFyuEnwZ8W6hXKcQI74YYSlTimhh8Gq5LrcY28YMAqJM6z6WMhWo1udRlouiML5w3rznUf5q48VNiyj8//bOBbiK6ozjm5tLQl4wIUCIJJGEQKzhEYKIgPigYnkFqxUrUltmlCnWx7TiVAs+AJ9oERgFpAioSBWmvEEQFJqI+ABqHV/FKmLH0lIpikyLVfDrnnMfudlzQm5yv03O3f3vzG9273dO9u41ifxy7t3vr5lrEoi5A6aBmDs+EHPHA2Lu/AVi7poIpFClQSkUMXcPAQA8w8cxUrhEM24Cpyx5fVIKN2nGQfxcFyOFH2jGTSA22eKwZtwE1lt11yhi7pzjpmDFSKFzzMuEvjfRgyYBKVRpUAoRcweAtyhNkpXCzmEpHK0ZA/HzJFYK2TE55u6TsBT+SzPmZZwxd0VFRdFbl2OZ+ugT9OsH51KXgq40bd5iOmfgICmFvc4fQ2PGjFHmN5W+laH2NDl5pdQuXBs9OnTujKAl953kHccZ1K1D3deJeoeUFBp26UjKTg/VGpNC8TVpmmvgoEEp1MwFACQ3UgqPqHWjOJwcbx8nA1IKf6nWjWKxzShN3SRqLfM7cnQLS2EnzZiXCfWPrF+cMmWKIoYy+3jbHnpk6fO0qOY9GXMnpHDWyleic7KLeskO3+K4tGsR9Tw71DixrGcxpWbkyIbPYlzE1xWU96Gy3r2lnInaM88sk3MfXfsS7Vn6U3kcm3zyoyElofFJ0+jmobY85pdQ2eAHZO2tkwflPtK8+nRSuOLT0FwRcxc5NydaKUTzat8gfnci33fgfdJO2VLo6FGaCPv27ZNNdZ31RCk7brYUii3SCNlkJh6YKHOanfXmEpuOwUYczaubwt69e2nLli1KPSGYm1eLTeQ5O+uJsm1n63ymUGwigCASMNAK1C/oYu7mbNhFr73+Os2a9TDNe36TjLkTUvjY6/+jQ4f2U4fS2+nBqtDcu6pKqPbpm23TvoJGFLehHc/NoUFXPCLHCgoKZFPqe2r+SeUFGXTf1tAP2/qNa6U0Pv6zMrpm3k5ZO3XiS/vchyjLqpNCy+ovpVAc95u2Ru5nf3BS7uORwtiYu9jXx4VOChFz5x8ghT6jraaWAJGkBWc9YfppaoZx9OhRpWYcMzS1BHBFCl2AXQpd4OTJkAew8o2m1gKIzRgpFB3Lp02b5pwgqamppdWrV1PfvpXycexKYcGUTXRdIDRv/oRyWvXACHl8zx130sgRP6cb566isnPuoypLxNeFpLDE/gt78zuhRJGly5dRl8Hj6cSJE3Ti669ldJ1upTBWCiunb5T7jd9+I/fxSOGBIy/I/aYFV0bPzYlOCrFS6B8ghf6Ce6XQLSk0faVQxI85aybix5VCAbsUMq8UDhs2TKlxgJVCq+GYO4GIv2mbkRF9HCuFKSkBGr3oL/Zfe19RaiAlKoUv7HmDrEABbZw5SsbXHf387/RdjBS2yaiiL+y/EJ/9/VO09I9vhc6dkk2fPXWVjMMTfz326KRK4cW3raCUQCods8c7ZIeiueKRwrSs9vbzHZMxd87Xx4FWCgshhX5BxEWJCClnHXiTtM62FB5Q681F/PxEIsfY+NCWwiqzpdCV1+0CE2+YSNatar25iNecmZmp1BNCNK1uJOauKbjyvRExd3019WbiyjUW21K43ZbCjpoxl3Hl9cRLIjF3LXn3cUVFRfRGEh09z/oepQfDx6eRQrfRSqG40aRMnQsASGIKwzeanKUZM4lB4RtNLtCMgfiZGb7RhHFl2BXOsIkjBrZVicTc7daMmcLO8I0mJl+jGwyTe81AHLSkFDYFI6UQLWkA8BZoSeMv0JKGH7SkMQ9nS5qmIFvSTHrUOAbNDH1u0CmFznlucO5doZtfFCm81P5vNs5cJr88WamZxriV45Qa8C75N+YrNaMYGSOFzjGTsMJSeL5mzCAqplcoNaMoiZFC55hJRP6NdtZNInKNYrXQOWYKVkzzaueYQdzyyi1KLSFC35vogacwKvtYM8ckEHMHTAMxd3wkQ59CxNwB00DMnccwSgp/Ydenm8vYfWOVmmlcuPNCpQa8S+68XKVmGqkzU5WacVhhKbxGM2YKVlgKf6AZM4jKdZVKzTisMM66SVhhREsn55gpWDFS6BwzhdQYKXSONRdLEj3wFEZJIT5TCABoDZLhM4Wio4SQQsY7e0ESgM8UJsbXYSmMzbxOFOdnCouLi5U0E8HUOU/Q7eGYuzvDMXei3mtoNVVXVyvzm0rffpWUnnuGPNeA7u0oEEyTx9XV3yerSwVd0LtAzutcEorDE6RltqfqMaPkse4aGpJCMdetmLsIihRq5gAAgOskQ8xdbXK8fZwUIOaOh27JEXMnpVB8Xlgz1iwSibkTdc6Yu/zBV8v5Mzd+Qm1yOsp+h/Lcl80O7ftdTfeGG1aXl59JWw/UkhXMpoXDgzR+2cF61yvQSaHbMXcR6kkhmleDZiK2yZMnJ0UEGDAXzubVIvZsyJAhSj1RLj5sthSKbcaMGTRnzhxlzCiYm1eLbcSIUN9hNpibV4ufSdHs2VlPFM7m1REfiOy5WPFafJ8pFJ/RbsJz1y+ImLvhw4fXqwkpfGlnDe3evZvmrd0RlcKH1+yxn6wbpbcvoSMHFtm1PnReaUd69Z0dZA2+iUqDFp34cBuVDhpHmQVn2uNt6LttN8nm1bMvK6YfPrSF8uzz/Oe99VIKxYW///LdUgrLyrpTaXGnOim0mRCWwlWr7qf9626T53vxpqy4pTASc/eHudco8zmJbPIxYu5AMxEbpBAkDHPMnRtSaP1YUzMIsSWFFLpAMtxg44YUuhFzd/DgQaWWEB9rahqaLYUizWTq1KnOCZKampp6MXeC2Ji76xuIuRtx2pi7UPsYEXMXWSmsmLhEv1Jo1Umh4OBbj9n7DNpwffwrhW7H3EWIbOIYK4WguYgNUggShXOlUOCGFGKlkAnmlULx/x9nLWGYVwoFbkgh50phUVERHT9+XKkniusrhU2JuRNwxtwJKRSxdm8umCClUBzLkHSNFO7atYi69h5KXxw+JB/HK4Vux9xFiGziGDF3oLmIyLxWizsC3oA55s6VCC5bYi4eY7YUijg69tftBoi544E55i5yjdzXueI5WwrPU+tOxPMKh3PWFRKJuWsxbCnccO/pP9Nw+KtvlZpOCluKelKIG00AAK0FbjTxF7jRhIduuNHEcxglhWhJAwBoDdCSBpgKWtIkRku0pPESRkkhYu4SBjF3/sL4mDub4PigUjMOKwli7qywFIq3FJ1jBnHR/IuUmnFE/h1y1k0ico2IuUuMQEzzaudYcwl9b6IHnsIoKdTMMQnE3AHTQMwdH8a/fWwlx9vHyXAXLuADMXceA1IYP5BCYBqQQj4ghTxACv0FpNBjQArjB1IITANSyAekkAdIob+AFJ6GjK7Z1HHQGdTr7vPo7N8MqKvndqGxY8cq8yOUdMqg3lUD7Hn5cl5VoTrHLRqSQnEdiLmrD6QQmAakkA9IIQ+QQn8BKWyEiBSW/6oqWtu8N9SnsNwmffImCjq+5sZLC+nxFWuo+Fw1m9htdFI4Zv6blGmV0uTRFcp8TiCF/EAK/QWkkA9IIQ+QQn8BKWwEIYXLn19Bi55ZHK1NWryXSrsVyeOIFN5yYSGNn7eDUq36Uti9e3fK0ZzXLXRS2Boxd5BCHiCF/gJSyAekkAdIob+AFDZCxbX9aeHCRbR6zVrK75pfN5ZVRDMH1Enhvz9cSoFR91Jny7yVwkjM3cb5LRhzBylkAVLoLyCFfEAKeYAU+gtIYSO0r8ij2tpa2r59OwWz2sjaY1MvoazCXnRtwJbCGzZTul17ckI5/e7VA0ZK4YSnP6Ecq4JGVXZU5nMCKeQHUugvIIV8QAp5gBT6C0ihx9BJYUsBKeQHUugvIIV8QAp5gBT6C0ihx4AUxg+kEJgGpJAPSCEPkEJ/ASn0GKZIYXBLkKyNltH0+bSPUjONnvt7KjXgXTJfzlRqphHYHFBqJpK1I0upmUbe7jylZhpFfy5SasC7DPx8oFIzjX6f9VNqCeMUGq9gihRipZAHrBT6C6wU8oGVQh6wUugvsFLoMSCF8QMpBKYBKeQDUsgDpNBfQAo9BqQwfiCFwDQghXxACnmAFPoLSOFpOGtK/2iiyTnzzf/lFUAK4wdSCEwDUsgHpJAHSKG/gBQ2QiIxd7kVw+TjnA7j6eHeBcq53UAnhYi50wMpBKYBKeQDUsgDpNBfQAobIRpztzw25m4PdS8plsfRmLsLCulqR8xdRAoF75zar5zbDXRSiJg7PZBCYBqQQj4ghTxACv0FpLARul3Sg5YsWUrr1m+gdu3bReuV07ZSZrBOCofetYGOHPtvvUSTWCn867fvKud2A60U/mmB3K+cPU6ZzwmkkB9Iob+AFPIBKeQBUugvIIWNkEjMXUQKO45cQOnBFOXcbqCTQsTc6YEUAtOAFPIBKeQBUugvIIUeQyeFLQWkkB9Iob+AFPIBKeQBUugvIIUeA1IYP5BCYBqQQj4ghTxACv0FpNBjmCKFqVtTydpkGU2fv/VRaqbRY38PpQa8S+aOTKVmGoEXAkrNRLJ2Zik108h7LU+pmUbh24VKDXgXGXOnqZtE5WeVSi1hnELjFUyRQqwU8oCVQn+BlUI+sFLIA1YK/QVWCj0GpDB+IIXANCCFfEAKeYAU+otkkMLLay4na4bFi/NJvAKkMH4ghcA0IIV8QAp5gBT6i2SQQutjm+nMKE+ioV7M3ePm//IKIIXxAykEpgEp5ANSyAOk0F8kjRRWM6M8SQPoYu5mrQzF3GV2KKB3HxmofI1g6aqF0eN/PPsTZdwttFLYqZwOHzuhzOUGUsgPpNBfQAr5gBTyACn0F5DCRhBSOPaOq2j0jCujNacUPnfkbfn4gRH9admLb9C62ZPo2c3b6IOP3qe2lgFSaPPbVz9SatxACvmBFPoLSCEfkEIeIIX+AlLYCLqYu9NJ4a5Pj1NORnpopTC3gm7tAyk0FUghMA1IIR+QQh4ghf4CUtgIkZi7bdu2UzAzFHPnlML793xpP76c5tpSeElPi5YvuxtSCClkAVLoLyCFfEAKeYAU+gtIYRxkZGRQ27Zto4+z2+fKfUogQHnZQhTbUn5+LmWntaHO+fmUmZYaWlUMBCkzaNlj+ZJAinpubhqSwpwO7uYeCyCF/EAK/QWkkA9IIQ+QQn8BKfQYDUlhSwAp5AdS6C8ghXxACnmAFPoLv0rh/wEy9VPHcEhvVgAAAABJRU5ErkJggg==>

[image2]: <data:image/png;base64,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>