# Computer Architecture: Pipeline RISC-V

## 1. Objetivo del proyecto
Este proyecto implementa un procesador RISC-V con arquitectura tipo pipeline (5 etapas) usando Verilog. El objetivo es ejecutar instrucciones de forma secuencial en el pipeline, mientras se manejan dependencias de datos mediante forwarding y stalls.

---

## 2. Visión general del diseño
El diseño está organizado en tres partes principales:

1. **Controlador**: genera las señales de control a partir del opcode y campos de la instrucción.
2. **Datapath**: contiene las etapas del pipeline y los registros intermedios.
3. **Hazard Unit**: detecta riesgos y decide cuándo hacer forwarding, stalls o flush.

La arquitectura usada sigue la idea general:

- Fetch (F)
- Decode (D)
- Execute (E)
- Memory (M)
- Writeback (W)

---

## 3. Estructura de archivos

- [riscvpipe.v](riscvpipe.v): módulo principal del procesador pipeline.
- [datapath.v](datapath.v): implementación del datapath completo.
- [hazard.v](hazard.v): unidad encargada de riesgos.
- [controller.v](controller.v): decodificador de control.
- [maindec.v](maindec.v): decodificador principal por opcode.
- [aludec.v](aludec.v): decodificador de la ALU.
- [regfile.v](regfile.v): banco de registros.
- [alu.v](alu.v): unidad aritmético-lógica.
- [extend.v](extend.v): extensor de inmediato.
- [imem.v](imem.v): memoria de instrucciones.
- [dmem.v](dmem.v): memoria de datos.
- [pipereg.v](pipereg.v): registros intermedios del pipeline.
- [mux2.v](mux2.v), [mux3.v](mux3.v): multiplexores.
- [adder.v](adder.v), [flopr.v](flopr.v): sumadores y registro para PC.
- [top.v](top.v): conexión entre procesador y memorias.
- [testbench.v](testbench.v): simulación para comprobar el funcionamiento.

---

## 4. Flujo general de una instrucción
Cada instrucción pasa por estas etapas:

### Fetch (F)
- Se lee la instrucción desde `imem` usando el PC actual.
- Se calcula `PC + 4`.
- Si corresponde, el PC puede ser actualizado con el resultado del branch o del salto.

### Decode (D)
- Se decodifica la instrucción.
- Se leen los registros fuente desde el banco de registros.
- Se extiende el inmediato según el tipo de instrucción.

### Execute (E)
- Se resuelven operaciones aritméticas/lógicas.
- Se calcula la dirección de branch/salto.
- Se decide si se debe usar forwarding.

### Memory (M)
- Si la instrucción es de carga o almacena, se accede a la memoria de datos.
- Se mantiene la información necesaria para el writeback.

### Writeback (W)
- Se selecciona el resultado que debe escribirse en el banco de registros.
- Puede ser:
  - resultado de la ALU,
  - dato cargado desde memoria,
  - `PC + 4` para instrucciones como `jal`.

---

## 5. Cómo funciona el program counter
El PC se mantiene en el registro `pcreg` y puede cambiar con:

- `PC + 4` (ejecución normal),
- la dirección objetivo de un branch/salto (`PCTargetE`),
- o una señal de stall que mantiene el mismo PC.

La lógica se ve así:

- `PCNextF = PCPlus4F` o `PCTargetE` según `PCSrcE`
- `PCInputF = PCNextF` o `PCF` según `StallF`

Esto evita que el PC avance cuando el pipeline está detenido por un hazard.

---

## 6. Banco de registros
El módulo [regfile.v](regfile.v) implementa un banco de registros de 32 entradas (`x0` a `x31`), aunque en este proyecto se usan principalmente las direcciones de 5 bits.

Características:
- Lectura combinacional.
- Escritura síncrona en flanco de subida.
- `x0` se mantiene en cero.

---

## 7. Unidad de control
La unidad de control recibe el opcode y genera señales como:

- `ResultSrc`
- `MemWrite`
- `Branch`
- `ALUSrc`
- `RegWrite`
- `Jump`
- `ImmSrc`
- `ALUControl`

### Decodificación por opcode
- `0000011` → `lw`
- `0100011` → `sw`
- `0110011` → instrucciones R-type
- `1100011` → `beq`
- `0010011` → instrucciones I-type ALU
- `1101111` → `jal`

---

## 8. Extensor de inmediato
El módulo [extend.v](extend.v) recibe el campo de instrucción y genera el inmediato extendido según el formato:

- `immsrc = 00` → I-type
- `immsrc = 01` → S-type
- `immsrc = 10` → B-type
- `immsrc = 11` → J-type

La extensión se hace con signo para que los valores negativos se representen correctamente.

---

## 9. ALU
La ALU en [alu.v](alu.v) soporta varias operaciones:

- suma
- resta
- AND
- OR
- XOR
- set less than (`slt`)
- shift left
- shift right

La señal `zero` indica si el resultado es cero, lo cual se usa para resolver branches.

---

## 10. Registros intermedios del pipeline
Los registros se implementan con [pipereg.v](pipereg.v), que tiene tres comportamientos:

- si `reset` → pone todo en cero
- si `clr` → limpia el registro (flush)
- si `en` → avanza el dato
- si `en = 0` y `clr = 0` → mantiene el valor (stall)

Esto permite detener el pipeline sin perder la información ya cargada en la etapa anterior.

---

## 11. Manejo de riesgos
Hay tres tipos de riesgos principales:

### 11.1 Hazard de datos
Ocurre cuando una instrucción necesita un dato que todavía no está disponible porque la instrucción anterior lo está calculando.

Ejemplo:
- una instrucción de carga (`lw`) produce un dato que otra instrucción necesita inmediatamente.

### 11.2 Forwarding
Si el dato ya está disponible en una etapa posterior, se adelanta con `mux3`:

- `ForwardAE`
- `ForwardBE`

Valores posibles:
- `00` → usar el dato normal del registro
- `01` → adelantar desde Writeback
- `10` → adelantar desde Memory

### 11.3 Stall por carga
Cuando una instrucción `lw` se encuentra en Execute y otra instrucción necesita ese resultado en Decode, el pipeline debe detenerse.

La lógica en [hazard.v](hazard.v) hace:

- `lwStall = ResultSrcE0 & ((Rs1D_ == RdE) | (Rs2D_ == RdE))`

Esto provoca:
- `StallF = 1`
- `StallD = 1`
- `FlushE = 1`

El efecto es evitar que una instrucción incorrecta avance en el pipeline.

---

## 12. Cómo se conectan las señales de control
El módulo [riscvpipe.v](riscvpipe.v) une el controlador con el datapath y la unidad de riesgos.

En resumen:
- el controlador recibe `InstrD` y produce señales de control para el datapath;
- el datapath produce información de registros y estados para la unidad de riesgos;
- la hazar unit devuelve señales de forwarding y stalling.

---

## 13. Qué hace el testbench
El testbench en [testbench.v](testbench.v) genera un reloj y reinicia el sistema.

Su objetivo es comprobar que el procesador escribe el valor esperado en memoria. Cuando se detecta una escritura correcta a la dirección esperada, el simulador muestra:

- `¡EXITO! El Pipeline Base funciona perfecto.`

---

## 14. Diagrama conceptual del pipeline

```text
Fetch ----> Decode ----> Execute ----> Memory ----> Writeback
   |            |           |          |            |
   |            |           |          |            |
   +------------+-----------+----------+------------+
         (hazards / forwarding / stalls)
```

---

## 15. Observaciones importantes

- El diseño funciona correctamente para el escenario validado por el testbench.
- La lógica de forwarding y stalls es una buena base para un pipeline real.
- Para una implementación más completa, se pueden añadir:
  - soporte a más instrucciones,
  - predicción de branches,
  - mejor manejo de riesgos estructurales,
  - mayor verificación con múltiples programas de prueba.

---

## 16. Cambios respecto a la versión inicial (SingleCycle)
La versión inicial del repositorio, identificada por el commit `6aabd5f138e55e7bb053af556e24add481da6055`, corresponde a un procesador **RISC-V SingleCycle**. El diseño actual es una versión **pipeline** que modifica tanto la organización del datapath como el manejo de señales de control.

### 16.1 Cambio de enfoque arquitectónico
En la versión single-cycle:
- cada instrucción se ejecuta completamente dentro de un mismo ciclo;
- el datapath usa una ruta lógica simple para calcular el resultado y actualizar el PC;
- no es necesario manejar dependencias entre instrucciones porque una instrucción finaliza antes de que la siguiente comience.

En la versión pipeline:
- una instrucción se divide en varias etapas que avanzan en paralelo;
- distintas instrucciones pueden estar activas en diferentes puntos del mismo instante;
- es necesario controlar cuándo una instrucción puede avanzar o debe detenerse.

### 16.2 Sustitución del módulo principal
La versión inicial usaba [riscvsingle.v](riscvsingle.v), mientras que la implementación actual usa [riscvpipe.v](riscvpipe.v).

La diferencia conceptual es que:
- `riscvsingle.v` conecta directamente el controlador con un datapath monociclo;
- `riscvpipe.v` conecta el controlador, el datapath pipeline y la unidad de riesgos.

### 16.3 Introducción de etapas separadas
En el diseño original, todas las operaciones ocurrían en una sola ruta de ejecución. En la versión actual, el datapath se reorganizó para tener:
- Fetch,
- Decode,
- Execute,
- Memory,
- Writeback.

Esto exige la presencia de registros entre etapas, implementados en [pipereg.v](pipereg.v).

### 16.4 Aparición de los registros intermedios
En single-cycle no existían registros que conservaran instrucciones o señales entre etapas. En pipeline sí aparecen:
- `IF/ID`,
- `ID/EX`,
- `EX/MEM`,
- `MEM/WB`.

Estos registros permiten que el procesador mantenga el estado correcto cuando varias instrucciones avanzan simultáneamente.

### 16.5 Nuevo manejo de señales de control
En la versión inicial, las señales de control se usaban directamente para ejecutar la instrucción actual.

En la versión actual, muchas de esas señales se propagan a través de stages para que cada etapa use la información correcta de la instrucción correspondiente. Por ejemplo:
- `ALUSrcD` y `ALUControlD` se mantienen hasta Execute;
- `MemWriteD` se conserva hasta Memory;
- `ResultSrcD` se mantiene hasta Writeback.

### 16.6 Adición de la unidad de riesgos
Este es probablemente el cambio más importante.

En el diseño single-cycle no había riesgo de datos entre instrucciones porque la siguiente instrucción no comenzaba hasta que la anterior terminaba. En pipeline sí aparece el problema de dependencias, por lo que se añadió [hazard.v](hazard.v).

La unidad de riesgos ahora decide:
- forwarding (`ForwardAE`, `ForwardBE`),
- stalls (`StallF`, `StallD`),
- flush (`FlushE`).

### 16.7 Modificación del control del PC
En single-cycle, el PC se actualiza según la instrucción actual.

En pipeline, el PC debe manejar correctamente:
- avance normal (`PC + 4`),
- branch/salto calculado en Execute,
- detenciones temporales para evitar usar datos incorrectos.

Por eso aparecen muxes adicionales como `pcmux` y `pcstallmux` en el datapath.

### 16.8 Impacto práctico de la migración
La transición de single-cycle a pipeline implica:
- mayor complejidad lógica,
- necesidad de sincronización entre etapas,
- manejo explícito de dependencias,
- mejor aprovechamiento del reloj para ejecutar instrucciones en serie con mayor rendimiento promedio.

En otras palabras: el diseño inicial ejecuta una instrucción completa antes de pasar a la siguiente, mientras que el diseño actual permite que varias instrucciones se superpongan en el tiempo.

---

## 17. Resumen rápido
En pocas palabras:
- el PC lleva la dirección de la siguiente instrucción;
- el controlador decide cómo ejecutar cada instrucción;
- el datapath mueve la instrucción a través del pipeline;
- la unidad de riesgos evita errores cuando dos instrucciones dependen entre sí;
- el banco de registros guarda los valores que se usarán y escribirán.
