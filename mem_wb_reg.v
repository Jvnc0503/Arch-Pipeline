module mem_wb_reg(input  clk, reset,
                   input  [31:0] ALUResult,
                   input  [31:0] ReadData,
                   input        RegWrite,
                   output [31:0] ALUResult_out,
                   output [31:0] ReadData_out,
                   output       RegWrite_out);

  reg [31:0] q_ALUResult;
  reg [31:0] q_ReadData;
  reg        q_RegWrite;

  assign ALUResult_out   = q_ALUResult;
  assign ReadData_out    = q_ReadData;
  assign RegWrite_out    = q_RegWrite;

  always @(posedge clk or posedge reset) begin
    if (reset) begin
      q_ALUResult <= 32'b0;
      q_ReadData  <= 32'b0;
      q_RegWrite  <= 1'b0;
    end else begin
      q_ALUResult   <= ALUResult;
      q_ReadData    <= ReadData;
      q_RegWrite    <= RegWrite;
    end
  end

endmodule