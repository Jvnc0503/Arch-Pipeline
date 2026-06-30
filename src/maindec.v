module maindec(
    input  wire [6:0] op,
    output wire [1:0] ResultSrc,
    output wire       MemWrite,
    output wire       Branch, 
    output wire       ALUSrc,
    output wire       RegWrite, 
    output wire       Jump,
    output wire       Jalr,
    output wire [2:0] ImmSrc,
    output wire [1:0] ALUOp
); 
    reg [12:0] controls;
    assign {RegWrite, ImmSrc, ALUSrc, MemWrite, ResultSrc, Branch, ALUOp, Jump, Jalr} = controls;
          
    always @* begin
        case(op)
            7'b0000011: controls = 13'b1_000_1_0_01_0_00_0_0; // lw
            7'b0100011: controls = 13'b0_001_1_1_00_0_00_0_0; // sw
            7'b0110011: controls = 13'b1_000_0_0_00_0_10_0_0; // R-type
            7'b1100011: controls = 13'b0_010_0_0_00_1_01_0_0; // B-type
            7'b0010011: controls = 13'b1_000_1_0_00_0_10_0_0; // I-type ALU
            7'b1101111: controls = 13'b1_011_0_0_10_0_00_1_0; // jal
            7'b1100111: controls = 13'b1_000_1_0_10_0_00_1_1; // jalr
            7'b0110111: controls = 13'b1_100_1_0_00_0_11_0_0; // lui
            default:    controls = 13'b0_000_0_0_00_0_00_0_0; 
        endcase
    end
endmodule