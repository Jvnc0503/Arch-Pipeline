`timescale 1ns/1ps

module testbench();
    reg         clk;
    reg         reset;
    wire [31:0] WriteData, DataAdr;
    wire        MemWrite;

    // Instancia de tu procesador
    top dut(
        .clk(clk), 
        .reset(reset), 
        .WriteData(WriteData), 
        .DataAdr(DataAdr), 
        .MemWrite(MemWrite)
    );

    // Inicialización
    initial begin
        reset <= 1; # 22; reset <= 0;
    end
    
    // Reloj
    always begin
        clk <= 1; # 5; clk <= 0; # 5;
    end

    // Monitor Universal de Resultados
    always @(negedge clk) begin
        if(MemWrite) begin
            // Imprime cada escritura en la consola para tu análisis
            $display("RAM Write: Escribio %d en la direccion %d", WriteData, DataAdr);
            
            // CONDICIÓN UNIVERSAL: Todos mis algoritmos terminan escribiendo en la dir 200
            if(DataAdr === 200) begin 
                $display("========================================");
                $display("¡EXITO TOTAL! El programa ha finalizado.");
                $display("Resultado final guardado: %d", WriteData);
                $display("========================================");
                $finish;
            end
        end
    end
endmodule