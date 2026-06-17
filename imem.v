module imem(
    input  wire [31:0] a,
    output wire [31:0] rd
);

    reg [31:0] RAM[63:0];

    initial begin
        $readmemh("riscvtest.mem", RAM);
    end

    // La memoria entrega la palabra completa alineada a 32 bits.
    // El descompresor decide qué 16 bits usar según la dirección del PC.
    assign rd = RAM[a[31:2]];
endmodule