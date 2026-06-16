module controller(
    input  wire [6:0] op,
    input  wire [2:0] funct3,
    input  wire funct7b5,
    input  wire Zero,
    output wire [1:0] ResultSrc, 
    output wire MemWrite,
    output wire ALUSrc,
    output wire RegWrite, 
    output wire Jump,
    output wire [1:0] ImmSrc, 
    output wire [2:0] ALUControl,
    output wire  Branch 
);
  
  wire [1:0] ALUOp;  
  
  maindec md(
    .op(op), 
    .ResultSrc(ResultSrc), 
    .MemWrite(MemWrite), 
    .Branch(Branch),     // Ahora Branch sale directo hacia el datapath
    .ALUSrc(ALUSrc), 
    .RegWrite(RegWrite), 
    .Jump(Jump), 
    .ImmSrc(ImmSrc), 
    .ALUOp(ALUOp)
  );

  aludec  ad(
    .opb5(op[5]), 
    .funct3(funct3), 
    .funct7b5(funct7b5), 
    .ALUOp(ALUOp), 
    .ALUControl(ALUControl)
  );
 
endmodule