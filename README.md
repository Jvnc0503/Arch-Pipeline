# Computer Architecture: Pipeline RISC-V

Este proyecto implementa un procesador RISC-V con arquitectura pipeline de 5 etapas en Verilog. El objetivo es demostrar cómo se ejecutan instrucciones en un diseño con forwarding, stalls y flushing, además de mostrar la interacción entre el datapath, la unidad de control y la unidad de riesgos.

---

## 1. Objetivo del proyecto

- Ejecutar instrucciones RISC-V siguiendo una arquitectura pipeline.
- Validar el comportamiento del diseño mediante una simulación con testbench.
- Comprender cómo se manejan dependencias de datos y control.

---

## 2. Visión general del diseño

El sistema está organizado en tres partes principales:

1. **Unidad de control**: decodifica el opcode y genera señales de control.
2. **Datapath**: ejecuta las etapas Fetch, Decode, Execute, Memory y Writeback.
3. **Hazard Unit**: detecta riesgos y decide si se aplica forwarding, stall o flush.

La arquitectura utilizada es:

- Fetch (F)
- Decode (D)
- Execute (E)
- Memory (M)
- Writeback (W)

---

## 3. Instrucciones típicamente usadas

El proyecto valida el funcionamiento del pipeline con instrucciones base de RISC-V, incluyendo operaciones de cálculo, carga/almacenamiento y control de flujo:

| Instrucción | Formato | Función principal | Uso en la validación |
| :--- | :--- | :--- | :--- |
| `addi` | I-type | Suma inmediata | Inicialización y pruebas de datos |
| `add` | R-type | Suma entre registros | Verificación de forwarding |
| `lw` | I-type | Carga desde memoria | Prueba de stall por dependencia |
| `sw` | S-type | Escritura a memoria | Validación del resultado final |
| `jal` | J-type | Salto incondicional | Verificación de flushing |
| `beq` | B-type | Comparación y salto condicional | Control de flujo |

---

## 4. Estructura de archivos

- [riscvpipe.v](riscvpipe.v): módulo principal del procesador pipeline.
- [riscvsingle.v](riscvsingle.v): versión monociclo del procesador para comparación.
- [datapath.v](datapath.v): implementación completa del datapath.
- [hazard.v](hazard.v): unidad encargada de la gestión de riesgos.
- [controller.v](controller.v): generador de señales de control.
- [maindec.v](maindec.v): decodificador principal por opcode.
- [aludec.v](aludec.v): decodificador de la ALU.
- [regfile.v](regfile.v): banco de registros.
- [alu.v](alu.v): unidad aritmético-lógica.
- [extend.v](extend.v): extensión del inmediato.
- [imem.v](imem.v): memoria de instrucciones.
- [dmem.v](dmem.v): memoria de datos.
- [pipereg.v](pipereg.v): registros intermedios del pipeline.
- [mux2.v](mux2.v), [mux3.v](mux3.v): multiplexores.
- [adder.v](adder.v), [flopr.v](flopr.v): sumadores y registros del PC.
- [top.v](top.v): conexión entre el procesador y las memorias.
- [testbench.v](testbench.v): simulación para verificar el comportamiento.
- [testprograms.txt](testprograms.txt): programas de prueba usados en la validación.
- [riscvtest.mem](riscvtest.mem): programa inicial cargado en la memoria de instrucciones.

---

## 5. Cómo simular el diseño

### Requisitos

- Un simulador Verilog compatible, como Icarus Verilog.
- El comando de compilación/ejecución se probó con:

```bash
iverilog -o pipeline_tb testbench.v top.v riscvpipe.v datapath.v controller.v maindec.v aludec.v regfile.v alu.v extend.v hazard.v flopr.v adder.v mux2.v mux3.v pipereg.v imem.v dmem.v
vvp pipeline_tb
```

### Resultado esperado

Si el programa de prueba termina correctamente, la simulación muestra:

```text
¡EXITO! El Pipeline Base funciona perfecto.
```

Este mensaje aparece cuando el testbench detecta que la instrucción final escribe el valor correcto en la memoria de datos.

---

## 6. Funcionamiento por etapas

### Fetch
- Se lee la instrucción desde la memoria usando el PC actual.
- Se calcula `PC + 4`.
- Si ocurre un salto o branch, el PC puede apuntar a otra dirección.

### Decode
- Se decodifica la instrucción.
- Se leen los registros fuente.
- Se extiende el inmediato según el formato de la instrucción.

### Execute
- Se realiza la operación en la ALU.
- Se calcula la dirección del salto o branch.
- Se aplica forwarding cuando el dato ya está disponible.

### Memory
- Si la instrucción requiere acceso a memoria, se lee o escribe en [dmem.v](dmem.v).

### Writeback
- Se elige el valor que se escribirá nuevamente en el banco de registros.
- Puede ser el resultado de la ALU, un dato cargado desde memoria o `PC + 4`.

---

## 7. Control del program counter

El PC se mantiene en un registro y puede avanzar en tres casos:

- `PC + 4` durante ejecución normal.
- la dirección objetivo calculada por un branch o salto.
- una detención temporal que mantiene el mismo valor para evitar usar datos incompletos.

---

## 8. Unidad de control

La unidad de control decodifica el opcode y genera señales como:

- `RegWrite`
- `MemWrite`
- `ALUSrc`
- `Branch`
- `Jump`
- `Jalr`
- `ResultSrc`
- `ImmSrc`
- `ALUControl`

Estas señales se propagan a lo largo del pipeline para que cada etapa opere con la instrucción correcta.

---

## 9. Gestión de hazards

La Hazard Unit corrige los problemas que aparecen cuando varias instrucciones avanzan simultáneamente.

### Forwarding
Permite usar el resultado ya calculado en una etapa posterior sin esperar a que termine la ejecución completa.

### Stalling
Cuando una instrucción `lw` produce un dato que otra instrucción necesita inmediatamente, el pipeline se detiene temporalmente para evitar lecturas incorrectas.

### Flushing
Cuando ocurre un salto o branch, se vacían las instrucciones que ya entraron incorrectamente al pipeline.

En el diseño, la unidad de riesgos produce señales como:

- `ForwardAE` y `ForwardBE`
- `StallF`, `StallD`
- `FlushE`

---

## 10. Programas de prueba usados

El proyecto incluye varios casos de validación:

### Programa 1: sin dependencias
Verifica el funcionamiento básico del pipeline con instrucciones separadas por `nop`.

### Programa 2: forwarding
Comprueba que un dato calculado previamente se use correctamente en la siguiente instrucción.

### Programa 3: stalling
Valida el caso `lw` seguido de un uso inmediato del dato cargado.

### Programa 4: flushing
Revisa el comportamiento ante un `jal` o un branch para confirmar que la instrucción equivocada no continúe ejecutándose.

---

## 11. Validación del diseño

El testbench genera el reloj y reinicia el sistema. La simulación verifica que el valor correcto se escriba en memoria y, cuando la operación esperada se cumple, imprime el mensaje de éxito.

En particular, se confirma que durante la escritura final:

- `DataAdr` apunta a la dirección correcta.
- `WriteData` contiene el valor esperado.

---

## 12. Resumen rápido

- El PC lleva la dirección de la siguiente instrucción.
- El controlador decide cómo ejecutar cada instrucción.
- El datapath mueve la instrucción a través del pipeline.
- La Hazard Unit evita errores al manejar dependencias de datos y de control.
- El banco de registros guarda los valores que se usan y escriben durante la ejecución.

---

## 13. Nota final

La implementación actual corresponde a una versión pipeline del procesador RISC-V, distinta de la versión monociclo. El cambio principal es la introducción de registros entre etapas y la necesidad de manejar correctamente hazards mediante forwarding, stalls y flush.
