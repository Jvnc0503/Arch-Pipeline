module alu(
    input  wire [31:0] a, b,
    input  wire [3:0]  alucontrol,
    output reg  [31:0] result,
    output wire        zero,
    output wire        lt
);
    always @* begin
        case(alucontrol)
            4'b0000: result = a + b;
            4'b0001: result = a - b;
            4'b0010: result = a & b;
            4'b0011: result = a | b;
            4'b0100: result = a ^ b;
            4'b0101: result = a << b[4:0];
            4'b0110: result = a >> b[4:0];
            4'b0111: result = $signed(a) >>> b[4:0];
            4'b1000: result = b;
            default: result = 32'bx;
        endcase
    end
    
    assign zero = (result == 32'b0);
    assign lt   = ($signed(a) < $signed(b));
endmodule