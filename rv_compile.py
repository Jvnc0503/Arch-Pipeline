import sys
import os

if len(sys.argv) != 2:
    print("Uso: python3 generar_mem.py archivo.s")
    sys.exit(1)

input_file = sys.argv[1]
base_name = os.path.splitext(input_file)[0]
obj_file = base_name + ".o"
mem_file = base_name + ".mem"

print(f"⚙️ Ensamblando {input_file}...")

# 1. Ensamblar el código (Mantiene la compatibilidad con RVC)
ret = os.system(f"riscv64-unknown-elf-as -march=rv32ic -mabi=ilp32 {input_file} -o {obj_file}")
if ret != 0:
    print("❌ Error: Fallo en el ensamblador.")
    sys.exit(1)

# 2. Extraer ÚNICAMENTE la sección de código (.text) a un binario puro
os.system(f"riscv64-unknown-elf-objcopy -O binary --only-section=.text {obj_file} text.bin")

# 3. Convertir el binario al formato estricto de 32 bits por línea
if os.path.exists("text.bin") and os.path.getsize("text.bin") > 0:
    with open("text.bin", "rb") as f_in, open(mem_file, "w") as f_out:
        while True:
            # Leer bloques exactos de 4 bytes
            chunk = f_in.read(4)
            if not chunk:
                break
            
            # Rellenar con ceros (equivalente a NOP) si la última instrucción es de 16 bits
            if len(chunk) < 4:
                chunk += b'\x00' * (4 - len(chunk))
            
            # Convertir a entero de 32 bits respetando el formato Little-Endian
            word = int.from_bytes(chunk, byteorder='little')
            
            # Escribir en formato hexadecimal de 8 caracteres
            f_out.write(f"{word:08x}\n")
            
    os.remove("text.bin")  # Limpieza del archivo temporal

os.remove(obj_file) # Limpieza del archivo objeto

print(f"✅ ¡Éxito! Archivo de instrucciones generado:")
print(f" 📄 {mem_file} -> Listo para cargar en tu Instruction Memory mediante $readmemh")