module datapath(
    input  clk, reset,
    
    // Señales de control que vienen del controller (nacen en Decode)
    input  [1:0] ResultSrcD, 
    input  PCSrcD, ALUSrcD, RegWriteD, MemWriteD, JumpD, BranchD,
    input  [1:0] ImmSrcD, 
    input  [2:0] ALUControlD,
    
    // Entradas y Salidas de la Memoria de Instrucciones (Etapa F)
    output [31:0] PCF,
    input  [31:0] InstrF,
    output wire [31:0] InstrD,
    
    // Entradas y Salidas de la Memoria de Datos (Etapa M)
    output [31:0] ALUResultM, WriteDataM, 
    input  [31:0] ReadDataM,
    output reg MemWriteM, // Esta señal viajó desde D hasta M
    
    // Inputs que vienen de la Hazard Unit
    input wire [1:0] ForwardAE, ForwardBE,
    input wire StallF, StallD, FlushE,
    
    // Outputs que van hacia la Hazard Unit para que pueda calcular los riesgos
    output wire [4:0]  Rs1D_, Rs2D_,
    output reg  [4:0]  Rs1E, Rs2E, RdE,
    output reg  [4:0]  RdM, RdW,
    output reg         RegWriteM, RegWriteW,
    output wire        ResultSrcE0, // Bit 0 de ResultSrcE para detectar 'lw'
    output wire        PCSrcE
);
  
  //Etapa de Fetch
  wire [31:0] PCNextF, PCPlus4F, PCInputF;
  wire [31:0] PCTargetE;  // Viene desde Execute
  
  mux2 #(32)  pcmux(.d0(PCPlus4F), .d1(PCTargetE), .s(PCSrcE), .y(PCNextF));
  mux2 #(32)  pcstallmux(.d0(PCNextF), .d1(PCF), .s(StallF), .y(PCInputF));
  flopr #(32) pcreg(.clk(clk), .reset(reset), .d(PCInputF), .q(PCF));
  adder       pcadd4(.a(PCF), .b(32'd4), .y(PCPlus4F));
  
  // MURO IF / ID 
  wire [31:0] PCD, PCPlus4D;
  
  pipereg r_if_id_instr (.clk(clk), .reset(reset), .en(~StallD), .clr(PCSrcE), .d(InstrF),   .q(InstrD));
  pipereg r_if_id_pc    (.clk(clk), .reset(reset), .en(~StallD), .clr(PCSrcE), .d(PCF),      .q(PCD));
  pipereg r_if_id_pc4   (.clk(clk), .reset(reset), .en(~StallD), .clr(PCSrcE), .d(PCPlus4F), .q(PCPlus4D));
  
  //Decode
  wire [31:0] RD1D, RD2D, ImmExtD;
  wire [4:0]  Rs1D = InstrD[19:15];
  wire [4:0]  Rs2D = InstrD[24:20];
  wire [4:0]  RdD  = InstrD[11:7];
  
  assign Rs1D_ = Rs1D;
  assign Rs2D_ = Rs2D;
  wire [31:0] ResultW;
  
  regfile rf(.clk(clk), .we3(RegWriteW), .a1(Rs1D), .a2(Rs2D), .a3(RdW), .wd3(ResultW), .rd1(RD1D), .rd2(RD2D));  
  // Extensión de Signo
  extend ext(.instr(InstrD[31:7]), .immsrc(ImmSrcD), .immext(ImmExtD));
  
  //ID / EX
  // Datos
  wire [31:0] RD1E, RD2E, PCE, ImmExtE, PCPlus4E;
  
  pipereg r_id_ex_rd1 (.clk(clk), .reset(reset), .en(1'b1), .clr(FlushE), .d(RD1D),     .q(RD1E));
  pipereg r_id_ex_rd2 (.clk(clk), .reset(reset), .en(1'b1), .clr(FlushE), .d(RD2D),     .q(RD2E));
  pipereg r_id_ex_imm (.clk(clk), .reset(reset), .en(1'b1), .clr(FlushE), .d(ImmExtD),  .q(ImmExtE));
  pipereg r_id_ex_pc  (.clk(clk), .reset(reset), .en(1'b1), .clr(FlushE), .d(PCD),      .q(PCE));
  pipereg r_id_ex_pc4 (.clk(clk), .reset(reset), .en(1'b1), .clr(FlushE), .d(PCPlus4D), .q(PCPlus4E));
  
  // Direcciones y Señales de Control
  reg       RegWriteE, MemWriteE, JumpE, BranchE, ALUSrcE;
  reg [1:0] ResultSrcE;
  reg [2:0] ALUControlE;
  
  always @(posedge clk or posedge reset) begin
        if (reset | FlushE) begin 
            RegWriteE   <= 0; MemWriteE   <= 0; JumpE <= 0; BranchE <= 0; ALUSrcE <= 0;
            ResultSrcE  <= 0; ALUControlE <= 0;
            Rs1E <= 0; Rs2E <= 0; RdE <= 0;
        end else begin
            RegWriteE   <= RegWriteD;
            MemWriteE   <= MemWriteD;
            JumpE       <= JumpD;
            BranchE     <= BranchD;
            ALUSrcE     <= ALUSrcD;
            ResultSrcE  <= ResultSrcD;
            ALUControlE <= ALUControlD;
            Rs1E        <= Rs1D;
            Rs2E        <= Rs2D;
            RdE         <= RdD;
        end
    end
    
   // EXECUTE
   
   wire [31:0] SrcAE, WriteDataE;
   wire [31:0] SrcBE, ALUResultE;
   wire ZeroE;
   
   // Seteamos el detector de 'lw' para la Hazard Unit
   assign ResultSrcE0 = ResultSrcE[0];
   
   // ALU y Mux de entrada B
   mux3 #(32) forwardamux(.d0(RD1E), .d1(ResultW), .d2(ALUResultM), .s(ForwardAE), .y(SrcAE));
   mux3 #(32) forwardbmux(.d0(RD2E), .d1(ResultW), .d2(ALUResultM), .s(ForwardBE), .y(WriteDataE));
   // El MUX original de inmediato ahora lee del dato filtrado por Forwarding
   mux2 #(32) srcbmux(.d0(WriteDataE), .d1(ImmExtE), .s(ALUSrcE), .y(SrcBE));
   
   // La ALU procesa el operando A adelantado
   alu  alu(.a(SrcAE), .b(SrcBE), .alucontrol(ALUControlE), .result(ALUResultE), .zero(ZeroE));
   adder pcaddbranch(.a(PCE), .b(ImmExtE), .y(PCTargetE));
   assign PCSrcE = (BranchE & ZeroE) | JumpE;
   
   // EX / MEM
   
   wire [31:0] PCPlus4M;
   pipereg r_ex_mem_alu(.clk(clk), .reset(reset), .en(1'b1), .clr(1'b0), .d(ALUResultE),  .q(ALUResultM));
   pipereg r_ex_mem_wd (.clk(clk), .reset(reset), .en(1'b1), .clr(1'b0), .d(WriteDataE), .q(WriteDataM));
   pipereg r_ex_mem_pc4(.clk(clk), .reset(reset), .en(1'b1), .clr(1'b0), .d(PCPlus4E),   .q(PCPlus4M));
   
   
   // Direcciones y Señales de Control
   reg [1:0] ResultSrcM;

   always @(posedge clk or posedge reset) begin
       if (reset) begin
           RegWriteM  <= 0; MemWriteM  <= 0; ResultSrcM <= 0; RdM <= 0;
       end else begin
           RegWriteM  <= RegWriteE;
           MemWriteM  <= MemWriteE; 
           ResultSrcM <= ResultSrcE;
           RdM        <= RdE;
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
            RegWriteW  <= 0; ResultSrcW <= 0; RdW <= 0;
        end else begin
            RegWriteW  <= RegWriteM;
            ResultSrcW <= ResultSrcM;
            RdW        <= RdM;
        end
    end
    
    // WRITEBACK
   mux3 #(32) resultmux(.d0(ALUResultW), .d1(ReadDataW), .d2(PCPlus4W), .s(ResultSrcW), .y(ResultW));
 endmodule