module datapath(
    input  wire        clk, reset,
    
    input  wire [1:0]  ResultSrcD, 
    input  wire        PCSrcD, ALUSrcD, RegWriteD, MemWriteD, JumpD, BranchD, JalrD,
    input  wire [2:0]  ImmSrcD, 
    input  wire [3:0]  ALUControlD,
    
    output wire [31:0] PCF,
    input  wire [31:0] InstrF,
    output wire [31:0] InstrD,
    
    output wire [31:0] ALUResultM, WriteDataM, 
    input  wire [31:0] ReadDataM,
    output reg         MemWriteM,
    
    input  wire [1:0]  ForwardAE, ForwardBE,
    input  wire        StallF, StallD, FlushE,
    
    output wire [4:0]  Rs1D_, Rs2D_,
    output reg  [4:0]  Rs1E, Rs2E, RdE,
    output reg  [4:0]  RdM, RdW,
    output reg         RegWriteM, RegWriteW,
    output wire        ResultSrcE0, 
    output wire        PCSrcE 
);
  
  //Etapa de Fetch
  wire [31:0] PCNextF, PCPlus4F, PCPlus2F, PCStepF, PCInputF;
  wire [31:0] PCTargetE;
  wire        IsCompressedF;
  wire [31:0] InstrFDec;

  decompressor dc(
      .instr(InstrF),
      .pc(PCF),
      .instr32(InstrFDec),
      .isCompressed(IsCompressedF),
      .pcstep(PCStepF)
  );

  adder       pcadd2(.a(PCF), .b(32'd2), .y(PCPlus2F));
  adder       pcadd4(.a(PCF), .b(32'd4), .y(PCPlus4F));
  mux2 #(32)  pcstepmux(.d0(PCPlus4F), .d1(PCPlus2F), .s(IsCompressedF), .y(PCStepF));
  mux2 #(32)  pcmux(.d0(PCStepF), .d1(PCTargetE), .s(PCSrcE), .y(PCNextF));
  mux2 #(32)  pcstallmux(.d0(PCNextF), .d1(PCF), .s(StallF), .y(PCInputF));
  flopr #(32) pcreg(.clk(clk), .reset(reset), .d(PCInputF), .q(PCF));

  // MURO IF / ID 
  wire [31:0] PCD, PCPlus4D;
  pipereg r_if_id_instr (.clk(clk), .reset(reset), .en(~StallD), .clr(PCSrcE), .d(InstrFDec), .q(InstrD));
  pipereg r_if_id_pc    (.clk(clk), .reset(reset), .en(~StallD), .clr(PCSrcE), .d(PCF),       .q(PCD));
  pipereg r_if_id_pc4   (.clk(clk), .reset(reset), .en(~StallD), .clr(PCSrcE), .d(PCPlus4F),  .q(PCPlus4D));
  
  //Decode
  wire [31:0] RD1D, RD2D, ImmExtD;
  wire [4:0]  Rs1D = InstrD[19:15];
  wire [4:0]  Rs2D = InstrD[24:20];
  wire [4:0]  RdD  = InstrD[11:7];
  wire [2:0]  funct3D = InstrD[14:12];
  
  assign Rs1D_ = Rs1D;
  assign Rs2D_ = Rs2D;
  
  wire [31:0] ResultW;
  
  regfile rf(.clk(clk), .we3(RegWriteW), .a1(Rs1D), .a2(Rs2D), .a3(RdW), .wd3(ResultW), .rd1(RD1D), .rd2(RD2D));
  extend ext(.instr(InstrD[31:7]), .immsrc(ImmSrcD), .immext(ImmExtD));
  
  //ID / EX
  wire [31:0] RD1E, RD2E, PCE, ImmExtE, PCPlus4E;
  pipereg r_id_ex_rd1 (.clk(clk), .reset(reset), .en(1'b1), .clr(FlushE), .d(RD1D),     .q(RD1E));
  pipereg r_id_ex_rd2 (.clk(clk), .reset(reset), .en(1'b1), .clr(FlushE), .d(RD2D),     .q(RD2E));
  pipereg r_id_ex_imm (.clk(clk), .reset(reset), .en(1'b1), .clr(FlushE), .d(ImmExtD),  .q(ImmExtE));
  pipereg r_id_ex_pc  (.clk(clk), .reset(reset), .en(1'b1), .clr(FlushE), .d(PCD),      .q(PCE));
  pipereg r_id_ex_pc4 (.clk(clk), .reset(reset), .en(1'b1), .clr(FlushE), .d(PCPlus4D), .q(PCPlus4E));
  
  reg       RegWriteE, MemWriteE, JumpE, BranchE, ALUSrcE, JalrE;
  reg [1:0] ResultSrcE;
  reg [3:0] ALUControlE;
  reg [2:0] funct3E;
  
  always @(posedge clk or posedge reset) begin
        if (reset | FlushE) begin 
            RegWriteE <= 0; MemWriteE <= 0; JumpE <= 0; BranchE <= 0; ALUSrcE <= 0; JalrE <= 0;
            ResultSrcE <= 0; ALUControlE <= 0; funct3E <= 0;
            Rs1E <= 0; Rs2E <= 0; RdE <= 0;
        end else begin
            RegWriteE   <= RegWriteD;  MemWriteE   <= MemWriteD;
            JumpE       <= JumpD;      BranchE     <= BranchD;
            ALUSrcE     <= ALUSrcD;    JalrE       <= JalrD;
            ResultSrcE  <= ResultSrcD; ALUControlE <= ALUControlD;
            funct3E     <= funct3D;
            Rs1E        <= Rs1D;       Rs2E        <= Rs2D;
            RdE         <= RdD;
        end
    end
    
   // EXECUTE
   
   // ¡CORREGIDO! Se agregó ALUResultE aquí para que sea de 32 bits
   wire [31:0] SrcAE, WriteDataE, SrcBE, ALUResultE;
   wire        ZeroE, LtE;
   
   // Seteamos el detector de 'lw' para la Hazard Unit
   assign ResultSrcE0 = ResultSrcE[0];
   
   // ALU y Mux de entrada B
   mux3 #(32) forwardamux(.d0(RD1E), .d1(ResultW), .d2(ALUResultM), .s(ForwardAE), .y(SrcAE));
   mux3 #(32) forwardbmux(.d0(RD2E), .d1(ResultW), .d2(ALUResultM), .s(ForwardBE), .y(WriteDataE));
   // El MUX original de inmediato ahora lee del dato filtrado por Forwarding
   mux2 #(32) srcbmux(.d0(WriteDataE), .d1(ImmExtE), .s(ALUSrcE), .y(SrcBE));
   
   // La ALU procesa el operando A adelantado
   alu alu(.a(SrcAE), .b(SrcBE), .alucontrol(ALUControlE), .result(ALUResultE), .zero(ZeroE), .lt(LtE));
   
   // EVALUADOR MULTI-BRANCH
   reg TakeBranchE;
   always @* case(funct3E)
       3'b000:  TakeBranchE = ZeroE;       // beq
       3'b001:  TakeBranchE = ~ZeroE;      // bne
       3'b100:  TakeBranchE = LtE;         // blt
       3'b101:  TakeBranchE = ~LtE;        // bge
       default: TakeBranchE = 1'b0;
   endcase

   wire [31:0] PCBranchE;
   adder pcaddbranch(.a(PCE), .b(ImmExtE), .y(PCBranchE));

   // Si es jalr -> Usa el ALUResult (Rs1 + Imm) limpiando el bit 0. Si no, usa PC + Imm
   assign PCTargetE = JalrE ? {ALUResultE[31:1], 1'b0} : PCBranchE;
   assign PCSrcE = (BranchE & TakeBranchE) | JumpE;
   
   // EX / MEM
   
   wire [31:0] PCPlus4M;
   pipereg r_ex_mem_alu(.clk(clk), .reset(reset), .en(1'b1), .clr(1'b0), .d(ALUResultE), .q(ALUResultM));
   pipereg r_ex_mem_wd (.clk(clk), .reset(reset), .en(1'b1), .clr(1'b0), .d(WriteDataE), .q(WriteDataM));
   
   // ¡CORREGIDO! Se cerró correctamente el paréntesis y el punto y coma de esta línea
   pipereg r_ex_mem_pc4(.clk(clk), .reset(reset), .en(1'b1), .clr(1'b0), .d(PCPlus4E),   .q(PCPlus4M));
   
   // Direcciones y Señales de Control
   reg [1:0] ResultSrcM;

   always @(posedge clk or posedge reset) begin
       if (reset) begin
           RegWriteM <= 0; MemWriteM <= 0; ResultSrcM <= 0; RdM <= 0;
       end else begin
           RegWriteM <= RegWriteE; MemWriteM <= MemWriteE; 
           ResultSrcM <= ResultSrcE; RdM <= RdE;
       end
    end
    
   // MEMORY
   
   wire [31:0] ALUResultW, ReadDataW, PCPlus4W;
   pipereg r_mem_wb_alu(.clk(clk), .reset(reset), .en(1'b1), .clr(1'b0), .d(ALUResultM), .q(ALUResultW));
   pipereg r_mem_wb_rd (.clk(clk), .reset(reset), .en(1'b1), .clr(1'b0), .d(ReadDataM),  .q(ReadDataW));
   pipereg r_mem_wb_pc4(.clk(clk), .reset(reset), .en(1'b1), .clr(1'b0), .d(PCPlus4M),   .q(PCPlus4W));
   
   reg [1:0] ResultSrcW;
   always @(posedge clk or posedge reset) begin
        if (reset) begin
            RegWriteW <= 0; ResultSrcW <= 0; RdW <= 0;
        end else begin
            RegWriteW <= RegWriteM; ResultSrcW <= ResultSrcM; RdW <= RdM;
        end
    end
    
   // WRITEBACK
   mux3 #(32) resultmux(.d0(ALUResultW), .d1(ReadDataW), .d2(PCPlus4W), .s(ResultSrcW), .y(ResultW));

endmodule