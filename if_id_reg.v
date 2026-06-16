module if_id_reg(input  clk, reset,
                 input  [31:0] Instr,
                 output [31:0] IF_ID_Instr);

  reg [31:0] q;
  assign IF_ID_Instr = q;

  always @(posedge clk or posedge reset) begin
    if (reset) q <= 32'b0;
    else       q <= Instr;
  end

endmodule