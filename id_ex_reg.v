module id_ex_reg(input  clk, reset,
                  input  [31:0] SrcA,
                  input  [31:0] WriteData,
                  input  [31:0] ImmExt,
                  input        ALUSrc,
                  input  RegWrite,
                  input  [1:0]  ResultSrc,
                  input  MemWrite,
                  input  [1:0]  ImmSrc,
                  input  [2:0]  ALUControl,
                  output [31:0] SrcA_out,
                  output [31:0] WriteData_out,
                  output [31:0] ImmExt_out,
                  output       ALUSrc_out,
                  output       RegWrite_out,
                  output [1:0]  ResultSrc_out,
                  output       MemWrite_out,
                  output [1:0]  ImmSrc_out,
                  output [2:0]  ALUControl_out);

  reg [31:0] q_SrcA;
  reg [31:0] q_WriteData;
  reg [31:0] q_ImmExt;
  reg        q_ALUSrc;
  reg        q_RegWrite;
  reg  [1:0] q_ResultSrc;
  reg        q_MemWrite;
  reg  [1:0] q_ImmSrc;
  reg  [2:0] q_ALUControl;

  assign SrcA_out       = q_SrcA;
  assign WriteData_out  = q_WriteData;
  assign ImmExt_out     = q_ImmExt;
  assign ALUSrc_out     = q_ALUSrc;
  assign RegWrite_out   = q_RegWrite;
  assign ResultSrc_out  = q_ResultSrc;
  assign MemWrite_out   = q_MemWrite;
  assign ImmSrc_out     = q_ImmSrc;
  assign ALUControl_out = q_ALUControl;

  always @(posedge clk or posedge reset) begin
    if (reset) begin
      q_SrcA       <= 32'b0;
      q_WriteData  <= 32'b0;
      q_ImmExt     <= 32'b0;
      q_ALUSrc     <= 1'b0;
      q_RegWrite   <= 1'b0;
      q_ResultSrc  <= 2'b00;
      q_MemWrite   <= 1'b0;
      q_ImmSrc     <= 2'b00;
      q_ALUControl <= 3'b000;
    end else begin
      q_SrcA       <= SrcA;
      q_WriteData  <= WriteData;
      q_ImmExt     <= ImmExt;
      q_ALUSrc     <= ALUSrc;
      q_RegWrite   <= RegWrite;
      q_ResultSrc  <= ResultSrc;
      q_MemWrite   <= MemWrite;
      q_ImmSrc     <= ImmSrc;
      q_ALUControl <= ALUControl;
    end
  end

endmodule