module alu(
    input  wire [31:0] a, b,
    input  wire [3:0]  alucontrol,
    output reg  [31:0] result,
    output wire        zero,
    output wire        lt   // Less Than (para blt y bge)
);
    always @* case(alucontrol)
        4'b0000: result = a + b;                   // add
        4'b0001: result = a - b;                   // sub
        4'b0010: result = a & b;                   // and
        4'b0011: result = a | b;                   // or
        4'b0100: result = a ^ b;                   // xor
        4'b0101: result = a << b[4:0];             // sll
        4'b0110: result = a >> b[4:0];             // srl
        4'b0111: result = $signed(a) >>> b[4:0];   // sra (aritmético)
        4'b1000: result = b;                       // pass B 
        default: result = 32'bx;
    endcase
    
    assign zero = (result == 32'b0);
    assign lt   = ($signed(a) < $signed(b));
endmodule