module controller(
    input  wire [6:0] op,
    input  wire [2:0] funct3,
    input  wire       funct7b5,
    output wire [1:0] ResultSrc, 
    output wire       MemWrite, ALUSrc, RegWrite, Jump, Jalr, Branch,     
    output wire [2:0] ImmSrc, 
    output wire [3:0] ALUControl       
);
    wire [1:0] ALUOp; 
    
    maindec md(
        .op(op), .ResultSrc(ResultSrc), .MemWrite(MemWrite), 
        .Branch(Branch), .ALUSrc(ALUSrc), .RegWrite(RegWrite), 
        .Jump(Jump), .Jalr(Jalr), .ImmSrc(ImmSrc), .ALUOp(ALUOp)
    ); 

    aludec ad(
        .opb5(op[5]), .funct3(funct3), .funct7b5(funct7b5), 
        .ALUOp(ALUOp), .ALUControl(ALUControl)
    ); 
endmodule