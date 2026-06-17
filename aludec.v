module aludec(
    input  wire [5:0] opb5, 
    input  wire [2:0] funct3,
    input  wire       funct7b5, 
    input  wire [1:0] ALUOp,
    output reg  [3:0] ALUControl
);
    always @* case(ALUOp)
        2'b00: ALUControl = 4'b0000; // lw, sw, jal, jalr
        2'b01: ALUControl = 4'b0001; // branch -> siempre restan para comparar
        2'b10: // R-type e I-type ALU
            case(funct3)
                3'b000: if (funct7b5 & opb5) ALUControl = 4'b0001; // sub (solo R-type)
                        else                 ALUControl = 4'b0000; // add / addi
                3'b100: ALUControl = 4'b0100; // xor, xori
                3'b110: ALUControl = 4'b0011; // or, ori
                3'b111: ALUControl = 4'b0010; // and, andi
                3'b001: ALUControl = 4'b0101; // sll, slli
                3'b101: if (funct7b5) ALUControl = 4'b0111; // sra, srai
                        else          ALUControl = 4'b0110; // srl, srli
                default: ALUControl = 4'bxxxx;
            endcase
        2'b11: ALUControl = 4'b1000; // lui -> Dejar pasar Inmediato
        default: ALUControl = 4'bxxxx;
    endcase
endmodule