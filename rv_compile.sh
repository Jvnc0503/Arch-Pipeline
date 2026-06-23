#!/bin/bash

# ==============================================================================
# Script de compilación RISC-V a Verilog Memory (.mem)
# Arquitectura: RV32IC (Base Integer + Compressed)
# ==============================================================================

# 1. Validación de argumentos
if [ "$#" -ne 1 ]; then
    echo "❌ Uso incorrecto."
    echo "💡 Forma de uso: ./rv_compile.sh <archivo.s>"
    exit 1
fi

INPUT_FILE="$1"

# 2. Validación de existencia del archivo
if [ ! -f "$INPUT_FILE" ]; then
    echo "❌ Error: El archivo '$INPUT_FILE' no existe en el directorio actual."
    exit 1
fi

# 3. Extracción del nombre base (sin extensión)
# Si el input es "quicksort.s", BASENAME será "quicksort"
FILENAME=$(basename "$INPUT_FILE")
BASENAME="${FILENAME%.*}"

OBJ_FILE="${BASENAME}.o"
MEM_FILE="${BASENAME}.mem"

echo "⚙️  Iniciando proceso para: $INPUT_FILE..."

# 4. Etapa de Ensamblaje
echo "   -> Ensamblando con arquitectura RV32IC..."
riscv64-unknown-elf-as -march=rv32ic -mabi=ilp32 "$INPUT_FILE" -o "$OBJ_FILE"

# Verificar si el ensamblador falló (código de salida distinto de 0)
if [ $? -ne 0 ]; then
    echo "❌ Error crítico: Falló la etapa de ensamblado. Revisa tu sintaxis."
    exit 1
fi

# 5. Etapa de Extracción (Objcopy)
echo "   -> Extrayendo hexadecimal a $MEM_FILE..."
riscv64-unknown-elf-objcopy -O verilog "$OBJ_FILE" "$MEM_FILE"

# Verificar si la extracción falló
if [ $? -ne 0 ]; then
    echo "❌ Error crítico: Falló la generación del archivo .mem."
    # Limpieza del archivo objeto parcial
    rm -f "$OBJ_FILE"
    exit 1
fi

# 6. Limpieza y finalización
# Borramos el archivo .o intermedio para mantener el directorio limpio
rm -f "$OBJ_FILE"

echo "✅ ¡Éxito! Archivo de memoria generado correctamente: $MEM_FILE"