module riscvpipe(
    input  wire        clk, reset,
    output wire [31:0] PCF,          
    input  wire [31:0] InstrF,       
    output wire        MemWriteM,    
    output wire [31:0] ALUResultM,   
    output wire [31:0] WriteDataM,   
    input  wire [31:0] ReadDataM     
);

    wire [31:0] InstrD;
    wire [1:0]  ResultSrcD;
    wire        ALUSrcD, RegWriteD, MemWriteD, JumpD, BranchD, JalrD;
    wire [2:0]  ImmSrcD;
    wire [3:0]  ALUControlD;

    wire [1:0]  ForwardAE, ForwardBE;
    wire        StallF, StallD, FlushE;
    wire [4:0]  Rs1D_, Rs2D_, Rs1E, Rs2E, RdE, RdM, RdW;
    wire        RegWriteM_wire, RegWriteW_wire, ResultSrcE0, PCSrcE;

    controller c(
        .op         (InstrD[6:0]),     
        .funct3     (InstrD[14:12]), 
        .funct7b5   (InstrD[30]), 
        .ResultSrc  (ResultSrcD), 
        .MemWrite   (MemWriteD), 
        .ALUSrc     (ALUSrcD), 
        .RegWrite   (RegWriteD), 
        .Jump       (JumpD),
        .Jalr       (JalrD),
        .ImmSrc     (ImmSrcD), 
        .ALUControl (ALUControlD),
        .Branch     (BranchD)
    ); 
  
    datapath dp(
        .clk        (clk), 
        .reset      (reset), 
        .ResultSrcD (ResultSrcD), 
        .PCSrcD     (1'b0), 
        .ALUSrcD    (ALUSrcD), 
        .RegWriteD  (RegWriteD),
        .MemWriteD  (MemWriteD),
        .JumpD      (JumpD),
        .BranchD    (BranchD),
        .JalrD      (JalrD),
        .ImmSrcD    (ImmSrcD), 
        .ALUControlD(ALUControlD),
        .PCF        (PCF),
        .InstrF     (InstrF),
        .InstrD     (InstrD),        
        .ALUResultM (ALUResultM), 
        .WriteDataM (WriteDataM), 
        .ReadDataM  (ReadDataM),
        .MemWriteM  (MemWriteM),
        .ForwardAE  (ForwardAE), 
        .ForwardBE  (ForwardBE),
        .StallF     (StallF), 
        .StallD     (StallD), 
        .FlushE     (FlushE),
        .Rs1D_      (Rs1D_), 
        .Rs2D_      (Rs2D_),
        .Rs1E       (Rs1E), 
        .Rs2E       (Rs2E), 
        .RdE        (RdE),
        .RdM        (RdM), 
        .RdW        (RdW),
        .RegWriteM  (RegWriteM_wire), 
        .RegWriteW  (RegWriteW_wire),
        .ResultSrcE0(ResultSrcE0),
        .PCSrcE     (PCSrcE)
    );

    hazard hu(
        .Rs1D_      (Rs1D_), 
        .Rs2D_      (Rs2D_),
        .Rs1E       (Rs1E), 
        .Rs2E       (Rs2E), 
        .RdE        (RdE),
        .RdM        (RdM), 
        .RdW        (RdW),
        .RegWriteM  (RegWriteM_wire), 
        .RegWriteW  (RegWriteW_wire),
        .ResultSrcE0(ResultSrcE0),
        .PCSrcE     (PCSrcE),
        .ForwardAE  (ForwardAE), 
        .ForwardBE  (ForwardBE),
        .StallF     (StallF), 
        .StallD     (StallD), 
        .FlushE     (FlushE)
    );
endmodule