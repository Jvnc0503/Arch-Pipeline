module imem(
    input  wire [31:0] a,
    output wire [31:0] rd
);
    reg [31:0] RAM[0:255]; 
    initial begin
        $readmemh("riscvtest.mem", RAM);
    end
    
    wire [29:0] word_addr = a[31:2]; 
    wire        half_aligned = a[1]; 

    assign rd = half_aligned ? {RAM[word_addr + 1][15:0], RAM[word_addr][31:16]} : RAM[word_addr];
endmodule