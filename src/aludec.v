module aludec(
    input  wire       opb5,
    input  wire [2:0] funct3,
    input  wire       funct7b5, 
    input  wire [1:0] ALUOp,
    output reg  [3:0] ALUControl
);
    always @* begin
        case(ALUOp)
            2'b00: ALUControl = 4'b0000; 
            2'b01: ALUControl = 4'b0001; 
            2'b10: begin
                case(funct3)
                    3'b000: begin
                        if (funct7b5 & opb5) ALUControl = 4'b0001; 
                        else                 ALUControl = 4'b0000; 
                    end
                    3'b100: ALUControl = 4'b0100; 
                    3'b110: ALUControl = 4'b0011; 
                    3'b111: ALUControl = 4'b0010; 
                    3'b001: ALUControl = 4'b0101; 
                    3'b101: begin
                        if (funct7b5) ALUControl = 4'b0111; 
                        else          ALUControl = 4'b0110; 
                    end
                    default: ALUControl = 4'bxxxx;
                endcase
            end
            2'b11: ALUControl = 4'b1000; 
            default: ALUControl = 4'bxxxx;
        endcase
    end
endmodule