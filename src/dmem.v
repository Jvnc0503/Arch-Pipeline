module dmem(
    input  wire        clk, we,
    input  wire [31:0] a, wd,
    output wire [31:0] rd
);
    reg [31:0] RAM[63:0];
    integer i;
    initial begin
        for (i = 0; i < 64; i = i + 1) begin
            RAM[i] = 32'd0;
        end
    end
    assign rd = RAM[a[31:2]]; 
    always @(posedge clk) begin
        if (we) RAM[a[31:2]] <= wd;
    end
endmodule