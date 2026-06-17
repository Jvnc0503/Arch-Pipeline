module decompressor(
    input  wire [31:0] instr,
    input  wire [31:0] pc,
    output reg  [31:0] instr32,
    output reg         isCompressed,
    output reg  [31:0] pcstep
);

    wire [15:0] c16 = pc[1] ? instr[31:16] : instr[15:0];
    wire        is_c = (c16[1:0] != 2'b11);

    function [4:0] r8_15;
        input [2:0] idx;
        begin
            r8_15 = idx + 5'd8;
        end
    endfunction

    always @* begin
        instr32     = instr;
        isCompressed = 1'b0;
        pcstep      = 32'd4;

        if (is_c) begin
            isCompressed = 1'b1;
            pcstep      = 32'd2;

            case (c16[15:13])
                3'b000: begin
                    // c.addi4spn (fallback simple)
                    instr32 = { {24{c16[12]}}, c16[12], c16[6:2], 5'b00010, 3'b000, 5'b00010, 7'b0010011 };
                end
                3'b001: begin
                    // c.jal
                    instr32 = { {11{c16[12]}}, c16[8], c16[10:9], c16[6], c16[7], c16[2], c16[11], c16[5:3], 1'b0, 8'b00000000, 7'b1101111 };
                end
                3'b010: begin
                    // c.lw
                    instr32 = { {21{c16[5]}}, c16[5], c16[12:10], c16[6], 2'b00, r8_15(c16[9:7]), 3'b010, r8_15(c16[4:2]), 7'b0000011 };
                end
                3'b011: begin
                    // c.lwsp / c.swsp (fallback)
                    instr32 = { {21{c16[5]}}, c16[5], c16[12:10], c16[6], 2'b00, 5'b00010, 3'b010, r8_15(c16[9:7]), 7'b0000011 };
                end
                3'b100: begin
                    if (c16[12] == 1'b0) begin
                        if (c16[11:10] == 2'b00) begin
                            instr32 = { 7'b0000000, c16[6:2], r8_15(c16[9:7]), 3'b101, r8_15(c16[9:7]), 7'b0010011 };
                        end else if (c16[11:10] == 2'b01) begin
                            instr32 = { 7'b0100000, c16[6:2], r8_15(c16[9:7]), 3'b101, r8_15(c16[9:7]), 7'b0010011 };
                        end else begin
                            instr32 = { {20{c16[6]}}, c16[6:2], r8_15(c16[9:7]), 3'b111, r8_15(c16[9:7]), 7'b0010011 };
                        end
                    end else begin
                        case (c16[11:10])
                            2'b00: instr32 = { 7'b0000000, r8_15(c16[4:2]), r8_15(c16[9:7]), 3'b000, r8_15(c16[9:7]), 7'b0110011 };
                            2'b01: instr32 = { 7'b0000000, r8_15(c16[4:2]), r8_15(c16[9:7]), 3'b100, r8_15(c16[9:7]), 7'b0110011 };
                            2'b10: instr32 = { 7'b0000000, r8_15(c16[4:2]), r8_15(c16[9:7]), 3'b110, r8_15(c16[9:7]), 7'b0110011 };
                            default: instr32 = { 7'b0000000, r8_15(c16[4:2]), r8_15(c16[9:7]), 3'b111, r8_15(c16[9:7]), 7'b0110011 };
                        endcase
                    end
                end
                3'b101: begin
                    instr32 = { {11{c16[12]}}, c16[8], c16[10:9], c16[6], c16[7], c16[2], c16[11], c16[5:3], 1'b0, 8'b00000000, 7'b1101111 };
                end
                3'b110: begin
                    instr32 = { {19{c16[12]}}, c16[12], c16[6], c16[5], c16[2], 5'b00000, r8_15(c16[9:7]), 3'b000, 1'b0, 7'b1100011 };
                end
                3'b111: begin
                    if (c16[11:7] != 5'b00000) begin
                        instr32 = { {15{c16[12]}}, c16[12], c16[6:2], c16[11:7], 7'b0110111 };
                    end
                end
                default: begin
                    instr32 = instr;
                end
            endcase
        end
    end
endmodule