Proyecto 2
3 Entregables : E1, E2, EF
E1( 5 pts) Sem 12.2, Deadline antes Sem 13.2
E2( 4 pts) Sem 12.2, Deadline antes de Sem 14.2
EF Sem 15 ( 3 pts + 8 pts presentación y preguntas) Deadline antes de Sem 15.1
Entregas adelantadas del E1 y E2 son bonificadas con 0.5 pts extra cada una.
Puntos extras trivia Sem 13.1 - 0.5 pts y Sem 14.1 - 0.5 pts
Entregas tardías -1 pt.
Faltas y tardanzas individual: Falta -0.5 pts
Tardanza -0.25 pts
E1 Entregables (5pts): Código del Pipeline funcionando
Archivos .mem para:
Test de pruebas de instrucciones (Cuadro 1)
Programa (1) ISA sin dependencias.
Test de prueba del Hazard unit
Programa (2) ISA test Forwarding
Programa (3) ISA test Stalling
Programa (4) ISA test Flushing
Informe:
Breve resumen de la teoría Pipeline: datapath, control. 0.5 pts
Implementación de instrucciones(Cuadro 1) 1.0 pts
Descripción de cambios en el código
Diagrama de datapath final
Programa ISA sin dependencias 1.0 pts
Waveform
Mostrar con resultados intermedios que el programa
funciona correctamente
Breve resumen de la teoría de Hazard unit. 0.5 pts
Mostrar que sin Hazard unit los programas (2,3 y 4) no
funcionan correctamente.
Implementación del Hazard unit 1.0 pts
Descripción de cambios en el código
Diagrama de datapath final
Programas de prueba 1.0 pts
Waveforms
Mostrar y explicar cómo el Hazard unit soluciona los
problemas de dependencia de sus programas de prueba.

E2 Entregables (4 pts): Parte 1: c.addi, c.add, c.sub, c.and, c.or, c.xor, c.slli,
c.srli, c.srai, c.lui
Código de la primera parte de las instrucciones comprimidas
Test de prueba de las instrucciones
Informe:
Implementación de instrucciones 2.0 pts
Explicar cómo funcionará cada nueva instrucción 1.5 pts
Código para cada instrucción explicado
Cambios extras en el datapath para adaptación 0.5 pts
Código de los cambios
Resultados: 2.0 pts
Programa ISA test ( que incluya instrucciones de 32 y 16 bits ) de
las instrucciones 0.5 pts
Waveform de todas/ importantes las instrucciones de su programa
explicadas 1.5 pts
*Mostrar con resultados que el programa funciona correctamente
E3 Entregables (3 pts): Parte 2: c.lw, c.sw, c.lwsp, c.swsp, c.beqz, c.bnez, c.j,
c.jal, c.jr, c.jalr
Código de la segunda parte de las instrucciones comprimidas
Test de prueba de las instrucciones
Informe:
Implementación de instrucciones 1.0 pts
Explicar cómo funcionará cada nueva instrucción 0.5 pts
Código para cada instrucción explicado
Cambios extras en el datapath para adaptación 0.25 pts
Código de los cambios
Encoding de todas las instrucciones pt1 y pt2 0.25 pts
Resultados: 2.0 pts
Programa ISA - algoritmo ( que incluya instrucciones de 32 y 16
bits ) de las instrucciones 0.5 pts
Waveform de todas/ importantes las instrucciones explicadas 1 pts
*Mostrar con resultados que el programa funciona correctamente
Comparativas entre los tamaños resultantes de los
programas y el performance 0.5 pts
Entrega 3: Sec 1, 2 Lunes 29/06 - Sec 3,4 Martes 30/06

| Presentación Final (8 pts):   |     | Presentación final ( 5 pts) 15 min  |     |     |     |
| ----------------------------- | --- | ----------------------------------- | --- | --- | --- |
          Explicación Pipeline funcionando con Hazard unit 0.5 pts
|     |     |     Explicación implementación instrucciones c 2 pts  |     |     |     |
| --- | --- | ----------------------------------------------------- | --- | --- | --- |
Explicación instrucciones importantes
|     |     |                                                       | Módulos agregados, cambios en el datapath   |     |     |
| --- | --- | ----------------------------------------------------- | ------------------------------------------- | --- | --- |
|     |     |                                                       | Encoding                                    |     |     |
|     |     |                                                       | Limitaciones                                |     |     |
|     |     |     Test programa ISA-algoritmo de prueba 2 pts       |                                             |     |     |
|     |     |                                                       | Explicación de resultados                   |     |     |
|     |     |                                                       | Comparativa tamaño y performance            |     |     |
|     |     |     Conclusiones, desafíos y mejoras 0.5 pts          |                                             |     |     |
|     |     |   Preguntas grupal e individual ( 1 pts + 2pts) 5min  |                                             |     |     |
|     |     |   Asistir sólo a su horario correspondiente :         |                                             |     |     |

| Grupo Sec 1  | Martes 30  |         | Grupo Sec 1  | Miércoles 01  |        |
| ------------ | ---------- | ------- | ------------ | ------------- | ------ |
|              | 1          | 15:15   |              | 5             | 12:00  |
|              | 2          | 15:40   |              | 8             | 12:25  |
|              | 3          | 16:05   |              | 4             | 12:50  |
|              | 9          | 16:30   |              | 6             | 13:15  |
|              |            |         |              | 7             | 13:40  |
| Grupo Sec 2  | Martes 30  |         |              |               |        |
|              | 3          | 17:00   | Grupo Sec 2  | Miércoles 01  |        |
|              | 4          | 17:25   |              | 1             | 15:15  |
|              | 2          | 17:50   |              | 7             | 15:40  |
|              | 5          | 17:15   |              |               |        |
|              | 6          | 17:40   | Grupo Sec 3  | Miércoles 01  |        |
|              |            |         |              | 3             | 17:00  |
|              |            |         |              | 2             | 17:25  |

| Grupo Sec 3  | Jueves 02  |         | Grupo Sec 4  | Viernes 03  |        |
| ------------ | ---------- | ------- | ------------ | ----------- | ------ |
|              | 5          | 12:00   |              | 5           | 12:15  |
|              | 7          | 12:25   |              | 6           | 12:40  |
|              | 1          | 12:50   |              | 8           | 13:05  |
|              | 6          | 13:15   |              | 4           | 13:30  |
|              | 4          | 13:40   |              |             |        |
|              |            |         |              |             |        |
| Grupo Sec 4  | Jueves 2   |         |              |             |        |
|              | 2          | 14:15   |              |             |        |
|              | 1          | 14:40   |              |             |        |
|              | 3          | 15:05   |              |             |        |
|              | 7          | 15:30   |              |             |        |