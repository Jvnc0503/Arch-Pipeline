`timescale 1ns / 1ps

module hazard(
    input  wire [4:0] Rs1D_, Rs2D_,
    input  wire [4:0] Rs1E, Rs2E, RdE,
    input  wire [4:0] RdM, RdW,
    input  wire       RegWriteM, RegWriteW,
    input  wire       ResultSrcE0,
    input  wire       PCSrcE,
    output reg  [1:0] ForwardAE, ForwardBE,
    output wire       StallF, StallD, FlushE
);

    // Forwarding
    always @* begin
        // Operando A
        if (((Rs1E == RdM) & RegWriteM) & (Rs1E != 0))      ForwardAE = 2'b10; // Adelanta desde Memory
        else if (((Rs1E == RdW) & RegWriteW) & (Rs1E != 0)) ForwardAE = 2'b01; // Adelanta desde Writeback
        else                                                ForwardAE = 2'b00; // Usa el valor normal del RegFile

        // Operando B
        if (((Rs2E == RdM) & RegWriteM) & (Rs2E != 0))      ForwardBE = 2'b10; // Adelanta desde Memory
        else if (((Rs2E == RdW) & RegWriteW) & (Rs2E != 0)) ForwardBE = 2'b01; // Adelanta desde Writeback
        else                                                ForwardBE = 2'b00; // Usa el valor normal
    end

    // Stall
    wire lwStall;
    assign lwStall = ResultSrcE0 & ((Rs1D_ == RdE) | (Rs2D_ == RdE));
    
    assign StallF = lwStall;
    assign StallD = lwStall;
    
    // Flush
    assign FlushE = lwStall | PCSrcE;

endmodule
