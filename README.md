# Computer Architecture: Pipeline RISC-V

## 1. Objetivo del proyecto
Este proyecto implementa un procesador RISC-V con arquitectura pipeline de 5 etapas en Verilog. El objetivo es ejecutar instrucciones de forma eficiente, manteniendo el flujo correcto del programa mediante registros intermedios, forwarding, stalls y flushing.

---

## 2. Visión general del diseño
El diseño se organiza en tres bloques principales:

1. **Unidad de control**: recibe el opcode y genera las señales necesarias para cada instrucción.
2. **Datapath**: contiene las etapas Fetch, Decode, Execute, Memory y Writeback.
3. **Hazard Unit**: detecta dependencias y decide cuándo aplicar forwarding, stall o flush.

La arquitectura usada es:

- Fetch (F)
- Decode (D)
- Execute (E)
- Memory (M)
- Writeback (W)

---

## 3. Instrucciones soportadas
El proyecto valida el funcionamiento del pipeline con instrucciones base de RISC-V:

| Instrucción | Formato | Función principal | Uso en la validación |
| :--- | :--- | :--- | :--- |
| `addi` | I-type | Suma inmediata | Inicialización y pruebas de datos |
| `add` | R-type | Suma entre registros | Verificación de forwarding |
| `lw` | I-type | Carga desde memoria | Prueba de stall por dependencia |
| `sw` | S-type | Escritura a memoria | Validación final del resultado |
| `jal` | J-type | Salto incondicional | Verificación de flushing |
| `beq` | B-type | Comparación y salto condicional | Control de flujo |

---

## 4. Estructura de archivos

- [riscvpipe.v](riscvpipe.v): módulo principal del procesador pipeline.
- [datapath.v](datapath.v): implementación del datapath completo.
- [hazard.v](hazard.v): unidad encargada de la gestión de riesgos.
- [controller.v](controller.v): decodificador de control.
- [maindec.v](maindec.v): decodificador principal por opcode.
- [aludec.v](aludec.v): decodificador de la ALU.
- [regfile.v](regfile.v): banco de registros.
- [alu.v](alu.v): unidad aritmético-lógica.
- [extend.v](extend.v): extensión de inmediato.
- [imem.v](imem.v): memoria de instrucciones.
- [dmem.v](dmem.v): memoria de datos.
- [pipereg.v](pipereg.v): registros intermedios del pipeline.
- [mux2.v](mux2.v), [mux3.v](mux3.v): multiplexores.
- [adder.v](adder.v), [flopr.v](flopr.v): sumadores y registros del PC.
- [top.v](top.v): conexión entre el procesador y las memorias.
- [testbench.v](testbench.v): simulación para verificar el comportamiento.
- [testprograms.txt](testprograms.txt): programas de prueba usados para validar el diseño.

---

## 5. Funcionamiento por etapas

### Fetch
- Se lee la instrucción desde la memoria de instrucciones usando el PC actual.
- Se calcula `PC + 4`.
- Si existe un salto o branch, el PC puede cambiar a la dirección objetivo.

### Decode
- Se decodifica la instrucción.
- Se leen los registros fuente.
- Se extiende el inmediato según el tipo de instrucción.

### Execute
- Se realiza la operación en la ALU.
- Se calcula la dirección de branch o salto.
- Se aplica forwarding cuando es posible.

### Memory
- Si la instrucción requiere acceso a memoria, se lee o escribe en `dmem`.

### Writeback
- Se elige el valor que se escribirá de nuevo en el banco de registros.
- Puede ser el resultado de la ALU, el dato cargado desde memoria o `PC + 4`.

---

## 6. Control del program counter
El PC se mantiene en un registro y puede avanzar en tres casos:

- `PC + 4` en ejecución normal.
- la dirección de destino calculada por un branch o salto.
- una detención temporal que mantiene el mismo valor para evitar usar datos incompletos.

---

## 7. Unidad de control
La unidad de control decodifica el opcode y genera señales como:

- `RegWrite`
- `MemWrite`
- `ALUSrc`
- `Branch`
- `Jump`
- `ResultSrc`
- `ImmSrc`
- `ALUControl`

Estas señales se propagan a lo largo del pipeline para que cada etapa opere con la instrucción correcta.

---

## 8. Hazard Unit
La Hazard Unit se encarga de corregir los riesgos que aparecen cuando varias instrucciones avanzan simultáneamente.

### 8.1 Forwarding
Permite usar el resultado ya calculado en una etapa posterior sin esperar a que termine el ciclo completo.

### 8.2 Stalling
Cuando una instrucción `lw` produce un dato que otra instrucción necesita inmediatamente, el pipeline se detiene temporalmente para evitar lecturas incorrectas.

### 8.3 Flushing
Cuando ocurre un salto o branch, se vacían las instrucciones que ya entraron incorrectamente al pipeline.

En el diseño, la unidad de riesgos genera:

- `ForwardAE` y `ForwardBE`
- `StallF`, `StallD`
- `FlushE`

Un ejemplo usado en la implementación es:

- `lwStall = ResultSrcE0 & ((Rs1D_ == RdE) | (Rs2D_ == RdE))`

Esto provoca que el pipeline detenga el Fetch/Decode y vacíe la etapa Execute cuando corresponde.

---

## 9. Programas de prueba usados
El informe incluye cuatro casos de validación:

### Programa 1: ISA sin dependencias
Verifica el funcionamiento básico del pipeline con instrucciones separadas por `nop`.

Ejemplo:

```asm
addi x2, x0, 5
addi x3, x0, 10
add  x4, x2, x3
sw   x4, 100(x0)
```

### Programa 2: Forwarding
Comprueba que el dato calculado por una instrucción anterior se use correctamente en la siguiente.

### Programa 3: Stalling
Valida el caso `lw` seguido de un uso inmediato del dato cargado.

### Programa 4: Flushing
Verifica el comportamiento correcto ante un `jal` o branch, asegurando que la instrucción equivocada no siga ejecutándose.

---

## 10. Validación del diseño
El testbench genera el reloj y reinicia el sistema, y la simulación verifica que el valor correcto se escriba en memoria. Cuando la operación esperada se cumple, el simulador reporta el mensaje de éxito.

En particular, se confirma que durante la escritura final:

- `DataAdr` apunta a la dirección correcta.
- `WriteData` contiene el valor esperado.

---

## 11. Resumen rápido
- El PC lleva la dirección de la siguiente instrucción.
- El controlador decide cómo ejecutar cada instrucción.
- El datapath mueve la instrucción a través del pipeline.
- La Hazard Unit evita errores al manejar dependencias de datos y de control.
- El banco de registros almacena los valores que se usan y escriben durante la ejecución.

---

## 12. Nota sobre la versión del proyecto
La implementación actual corresponde a una versión pipeline del procesador RISC-V, distinta de la versión monociclo inicial. El cambio principal es la introducción de registros entre etapas y la necesidad de manejar correctamente hazards mediante forwarding, stalls y flush.
