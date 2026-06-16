module ex_mem_reg(input  clk, reset,
                   input  [31:0] ALUResult,
                   input  [31:0] SrcA,
                   input  [31:0] WriteData,
                   input        RegWrite,
                   input  [1:0]  ResultSrc,
                   input        MemWrite,
                   output [31:0] ALUResult_out,
                   output [31:0] SrcA_out,
                   output [31:0] WriteData_out,
                   output       RegWrite_out,
                   output [1:0]  ResultSrc_out,
                   output       MemWrite_out);

  reg [31:0] q_ALUResult;
  reg [31:0] q_SrcA;
  reg [31:0] q_WriteData;
  reg        q_RegWrite;
  reg  [1:0] q_ResultSrc;
  reg        q_MemWrite;

  assign ALUResult_out   = q_ALUResult;
  assign SrcA_out        = q_SrcA;
  assign WriteData_out   = q_WriteData;
  assign RegWrite_out    = q_RegWrite;
  assign ResultSrc_out   = q_ResultSrc;
  assign MemWrite_out    = q_MemWrite;

  always @(posedge clk or posedge reset) begin
    if (reset) begin
      q_ALUResult <= 32'b0;
      q_SrcA      <= 32'b0;
      q_WriteData <= 32'b0;
      q_RegWrite  <= 1'b0;
      q_ResultSrc <= 2'b00;
      q_MemWrite  <= 1'b0;
    end else begin
      q_ALUResult   <= ALUResult;
      q_SrcA        <= SrcA;
      q_WriteData   <= WriteData;
      q_RegWrite    <= RegWrite;
      q_ResultSrc   <= ResultSrc;
      q_MemWrite    <= MemWrite;
    end
  end

endmodule