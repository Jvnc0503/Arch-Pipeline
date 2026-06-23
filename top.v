module top(
    input  wire        clk, reset,
    output wire [31:0] WriteData, DataAdr,
    output wire        MemWrite
);
    wire [31:0] PC, Instr, ReadData;
    
    riscvpipe rvpipe(
        .clk(clk), 
        .reset(reset), 
        .PCF(PC), 
        .InstrF(Instr), 
        .MemWriteM(MemWrite), 
        .ALUResultM(DataAdr), 
        .WriteDataM(WriteData), 
        .ReadDataM(ReadData)
    );
    
    imem imem(.a(PC), .rd(Instr));
    dmem dmem(.clk(clk), .we(MemWrite), .a(DataAdr), .wd(WriteData), .rd(ReadData));
endmodule