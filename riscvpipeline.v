module riscvpipeline(input  clk, reset,
                      output [31:0] PC,
                      input  [31:0] Instr,
                      output MemWrite,
                      output [31:0] DataAdr, 
                      output [31:0] WriteData,
                      input  [31:0] ReadData);

  // ===== IF/ID Pipeline Register Signals =====
  wire [31:0] IF_ID_Instr;       // Instruction from IF stage to ID stage

  // ===== ID/EX Pipeline Register Signals =====
  wire [31:0] ID_EX_SrcA;        // First operand for ALU (from register file)
  wire [31:0] ID_EX_ImmExt;      // Extended immediate value
  wire        ID_EX_ALUSrc;       // ALU source select
  wire        ID_EX_RegWrite;     // Register write enable
  wire  [1:0] ID_EX_ResultSrc;   // Result source selector
  wire        ID_EX_MemWrite;     // Memory write signal
  wire  [1:0] ID_EX_ImmSrc;       // Immediate source select
  wire  [2:0] ID_EX_ALUControl;   // ALU control signals

  // ===== EX/MEM Pipeline Register Signals =====
  wire [31:0] EX_MEM_ALUResult;  // ALU result to MEM stage
  wire        EX_MEM_RegWrite;   // RegWrite signal for WB
  wire  [1:0] EX_MEM_ResultSrc;  // Result source for WB
  wire        EX_MEM_MemWrite;   // MemWrite signal

  // ===== MEM/WB Pipeline Register Signals =====
  wire [31:0] MEM_WB_ALUResult;  // ALU result to WB stage
  wire [31:0] MEM_WB_ReadData;   // Data read from memory
  wire        MEM_WB_RegWrite;   // RegWrite signal for WB

  // ===== Control signals (decoded in ID stage) =====
  wire [6:0]  op;
  wire [2:0]  funct3;
  wire        funct7b5;
  wire        Zero;
  wire  [1:0] ResultSrc;
  wire        MemWrite_ctrl;
  wire        PCSrc;
  wire        ALUSrc;
  wire        RegWrite_ctrl;
  wire        Jump;
  wire  [1:0] ImmSrc;
  wire  [2:0] ALUControl;

  // ===== IF Stage: Fetch instruction and update PC =====
  assign op       = IF_ID_Instr[6:0];
  assign funct3   = IF_ID_Instr[14:12];
  assign funct7b5 = IF_ID_Instr[30];

  // Controller (ID stage - decodes instruction)
  controller c(
    .op(op), 
    .funct3(funct3), 
    .funct7b5(funct7b5), 
    .Zero(Zero),
    .ResultSrc(ResultSrc), 
    .MemWrite(MemWrite_ctrl), 
    .PCSrc(PCSrc),
    .ALUSrc(ALUSrc), 
    .RegWrite(RegWrite_ctrl), 
    .Jump(Jump),
    .ImmSrc(ImmSrc), 
    .ALUControl(ALUControl)
  );

  // ===== Datapath with Pipeline Registers =====
  datapath dp(
    .clk(clk), 
    .reset(reset),
    .ResultSrc(ResultSrc), 
    .PCSrc(PCSrc),
    .ALUSrc(ALUSrc), 
    .RegWrite(RegWrite_ctrl),
    .ImmSrc(ImmSrc), 
    .ALUControl(ALUControl),
    .Zero(Zero), 
    .PC(PC), 
    .Instr(IF_ID_Instr),  // Use instruction from IF/ID register
    .SrcA(ID_EX_SrcA),     // Exposed for ID/EX register
    .ImmExt(ID_EX_ImmExt), // Exposed for ID/EX register
    .ALUResult(EX_MEM_ALUResult),  // ALU result to EX/MEM register
    .WriteData(WriteData), 
    .ReadData(ReadData)
  );

  // ===== Pipeline Registers =====
  
  // IF/ID Register: Stores instruction fetched from memory
  if_id_reg if_id(
    .clk(clk), 
    .reset(reset),
    .Instr(Instr),       // Instruction from imem
    .IF_ID_Instr(IF_ID_Instr)
  );

  // ID/EX Register: Stores decoded instruction data and control signals
  id_ex_reg id_ex(
    .clk(clk), 
    .reset(reset),
    .SrcA(ID_EX_SrcA),         // From register file read port 1
    .ImmExt(ID_EX_ImmExt),     // Extended immediate from extend module
    .ALUSrc(ALUSrc),           // ALU source select
    .RegWrite(RegWrite_ctrl),  // Register write enable
    .ResultSrc(ResultSrc),     // Result source selector
    .MemWrite(MemWrite_ctrl),  // Memory write signal
    .ImmSrc(ImmSrc),           // Immediate source select
    .ALUControl(ALUControl),   // ALU control signals
    .SrcA_out(ID_EX_SrcA),     // Output to EX stage
    .ImmExt_out(ID_EX_ImmExt),
    .ALUSrc_out(ID_EX_ALUSrc),
    .RegWrite_out(ID_EX_RegWrite),
    .ResultSrc_out(ID_EX_ResultSrc),
    .MemWrite_out(ID_EX_MemWrite),
    .ImmSrc_out(ID_EX_ImmSrc),
    .ALUControl_out(ID_EX_ALUControl)
  );

  // EX/MEM Register: Stores ALU result and data for MEM stage
  ex_mem_reg ex_mem(
    .clk(clk), 
    .reset(reset),
    .ALUResult(EX_MEM_ALUResult),   // From ALU output
    .RegWrite(EX_MEM_RegWrite),     // RegWrite signal
    .ResultSrc(EX_MEM_ResultSrc),   // Result source selector
    .MemWrite(EX_MEM_MemWrite),     // MemWrite signal
    .ALUResult_out(EX_MEM_ALUResult),
    .RegWrite_out(EX_MEM_RegWrite),
    .ResultSrc_out(EX_MEM_ResultSrc),
    .MemWrite_out(EX_MEM_MemWrite)
  );

  // MEM/WB Register: Stores data from memory for WB stage
  mem_wb_reg mem_wb(
    .clk(clk), 
    .reset(reset),
    .ALUResult(MEM_WB_ALUResult),   // From EX/MEM register
    .ReadData(MEM_WB_ReadData),     // Data from dmem
    .RegWrite(MEM_WB_RegWrite),     // RegWrite signal
    .ALUResult_out(MEM_WB_ALUResult),
    .ReadData_out(MEM_WB_ReadData),
    .RegWrite_out(MEM_WB_RegWrite)
  );

  // Datapath reestructurado para pipeline
  datapath dp(
    .clk(clk), 
    .reset(reset),
    .ResultSrc(ResultSrc), 
    .PCSrc(PCSrc),
    .ALUSrc(ALUSrc), 
    .RegWrite(RegWrite_ctrl),
    .ImmSrc(ImmSrc), 
    .ALUControl(ALUControl),
    .Zero(Zero), 
    .PC(PC), 
    .Instr(IF_ID_Instr),  // Usar instrucción del registro IF/ID
    .ALUResult(ID_EX_ImmExt),  // Esto no es correcto, necesito reestructurar
    .WriteData(WriteData), 
    .ReadData(ReadData)
  );

  // Registros de pipeline
  if_id_reg if_id(
    .clk(clk), 
    .reset(reset),
    .Instr(Instr),
    .Instr_out(IF_ID_Instr)
  );

  id_ex_reg id_ex(
    .clk(clk), 
    .reset(reset),
    // inputs desde ID stage
    .SrcA(ID_EX_SrcA),
    .WriteData(ID_EX_WriteData),
    .ImmExt(ID_EX_ImmExt),
    .ALUSrc(ALUSrc),
    .RegWrite(RegWrite_ctrl),
    .ResultSrc(ResultSrc),
    .MemWrite(MemWrite_ctrl),
    .ImmSrc(ImmSrc),
    .ALUControl(ALUControl),
    // outputs para EX stage
    .SrcA_out(ID_EX_SrcA),
    .WriteData_out(ID_EX_WriteData),
    .ImmExt_out(ID_EX_ImmExt),
    .ALUSrc_out(ID_EX_ALUSrc),
    .RegWrite_out(ID_EX_RegWrite),
    .ResultSrc_out(ID_EX_ResultSrc),
    .MemWrite_out(ID_EX_MemWrite),
    .ImmSrc_out(ID_EX_ImmSrc),
    .ALUControl_out(ID_EX_ALUControl)
  );

  ex_mem_reg ex_mem(
    .clk(clk), 
    .reset(reset),
    // inputs desde EX stage
    .ALUResult(EX_MEM_ALUResult),
    .SrcA(EX_MEM_SrcA),
    .WriteData(EX_MEM_WriteData),
    .RegWrite(EX_MEM_RegWrite),
    .ResultSrc(EX_MEM_ResultSrc),
    .MemWrite(EX_MEM_MemWrite),
    // outputs para MEM stage
    .ALUResult_out(EX_MEM_ALUResult),
    .SrcA_out(EX_MEM_SrcA),
    .WriteData_out(EX_MEM_WriteData),
    .RegWrite_out(EX_MEM_RegWrite),
    .ResultSrc_out(EX_MEM_ResultSrc),
    .MemWrite_out(EX_MEM_MemWrite)
  );

  mem_wb_reg mem_wb(
    .clk(clk), 
    .reset(reset),
    // inputs desde MEM stage
    .ALUResult(MEM_WB_ALUResult),
    .ReadData(MEM_WB_ReadData),
    .RegWrite(MEM_WB_RegWrite),
    // outputs para WB stage
    .ALUResult_out(MEM_WB_ALUResult),
    .ReadData_out(MEM_WB_ReadData),
    .RegWrite_out(MEM_WB_RegWrite)
  );

endmodule