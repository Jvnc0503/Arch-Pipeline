# Arquitectura de Computadoras — Pipeline RISC-V con soporte preliminar de RVC

Este proyecto implementa un pipeline de 5 etapas para un procesador RISC-V y además incorpora una primera versión del soporte para instrucciones comprimidas (extensión C). El objetivo es mostrar cómo el datapath, la unidad de control y la unidad de riesgos trabajan conjuntamente con instrucciones de 32 bits y con una ruta de descompresión para instrucciones de 16 bits.

---

## 1. Objetivo del proyecto

- Ejecutar correctamente un pipeline RISC-V base.
- Integrar una etapa de descompresión para instrucciones comprimidas.
- Ajustar el control del PC para avanzar 2 bytes cuando la instrucción actual es comprimida.
- Validar el funcionamiento mediante simulación con Icarus Verilog.

---

## 2. Estructura general

El diseño sigue una organización tipo pipeline:

1. **Fetch**: lectura de la instrucción y actualización del PC.
2. **Decode**: decodificación y lectura del banco de registros.
3. **Execute**: ALU y cálculo de direcciones de salto.
4. **Memory**: acceso a memoria de datos.
5. **Writeback**: escritura del resultado al registro correspondiente.

Además, se incluyen:

- **Hazard Unit** para forwarding, stalls y flush.
- **Decompressor** para expandir instrucciones de 16 bits a 32 bits.

---

## 3. Cambios incorporados para la extensión C

### 3.1 Módulo de descompresión
Se añadió el archivo [decompressor.v](decompressor.v), que recibe una instrucción leída desde la memoria y genera:

- la instrucción expandida de 32 bits,
- una señal que indica si la instrucción era comprimida,
- el paso del PC correspondiente (`2` o `4` bytes).

### 3.2 Ajuste del Fetch
En [datapath.v](datapath.v), el PC ahora puede avanzar de dos formas:

- `PC + 4` para instrucciones normales de 32 bits.
- `PC + 2` para instrucciones comprimidas.

La lógica de descompresión se aplica antes de que la instrucción continúe por el pipeline.

### 3.3 Memoria de instrucciones
La memoria en [imem.v](imem.v) sigue entregando palabras de 32 bits alineadas, y el descompresor usa la instrucción correcta según la dirección del PC.

---

## 4. Archivos principales

- [riscvpipe.v](riscvpipe.v): módulo principal del pipeline.
- [datapath.v](datapath.v): implementación del datapath y del nuevo control del PC.
- [decompressor.v](decompressor.v): módulo de expansión de instrucciones comprimidas.
- [hazard.v](hazard.v): gestión de forwarding, stalls y flush.
- [controller.v](controller.v): señales de control globales.
- [maindec.v](maindec.v): decodificador por opcode.
- [aludec.v](aludec.v): decodificador para la ALU.
- [regfile.v](regfile.v): banco de registros.
- [alu.v](alu.v): unidad aritmético-lógica.
- [extend.v](extend.v): extensión de inmediatos.
- [imem.v](imem.v): memoria de instrucciones.
- [dmem.v](dmem.v): memoria de datos.
- [pipereg.v](pipereg.v): registros intermedios del pipeline.
- [mux2.v](mux2.v), [mux3.v](mux3.v): multiplexores.
- [adder.v](adder.v), [flopr.v](flopr.v): sumadores y registros del PC.
- [top.v](top.v): conexión del procesador con memorias.
- [testbench.v](testbench.v): simulación del sistema.
- [riscvtest.mem](riscvtest.mem): programa base cargado en la memoria.

---

## 5. Cómo compilar y ejecutar

### Requisitos

- Icarus Verilog (`iverilog`)
- `vvp`

### Comando de compilación

```bash
iverilog -o pipeline_tb \
  testbench.v top.v riscvpipe.v datapath.v controller.v \
  maindec.v aludec.v regfile.v alu.v extend.v hazard.v \
  flopr.v adder.v mux2.v mux3.v pipereg.v imem.v dmem.v \
  decompressor.v
```

### Ejecución

```bash
vvp pipeline_tb
```

### Resultado esperado

Si la simulación termina correctamente, el testbench imprime:

```text
¡EXITO! El Pipeline Base funciona perfecto.
```

---

## 6. Validación realizada

La compilación y la simulación del proyecto fueron verificadas con los comandos anteriores. El resultado observado muestra que el pipeline base sigue ejecutando correctamente y que el diseño ahora incluye la lógica necesaria para incorporar instrucciones comprimidas en el flujo principal.

---

## 7. Nota importante

La implementación actual de la extensión C es una primera integración práctica sobre el pipeline base. Para la entrega final, conviene complementar esta versión con programas de prueba específicos en ensamblador que mezclen instrucciones RV32I y RVC, además de mostrar comparaciones de tamaño y comportamiento en waveform.
