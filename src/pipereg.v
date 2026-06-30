module pipereg #(parameter WIDTH = 32)(
    input  wire             clk, reset, en, clr,
    input  wire [WIDTH-1:0] d,
    output reg  [WIDTH-1:0] q
);
    always @(posedge clk or posedge reset) begin
        if (reset)      q <= 0;
        else if (clr)   q <= 0;
        else if (en)    q <= d;
    end
endmodule