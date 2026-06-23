module decompressor(
    input  wire [15:0] instr_c,
    output reg  [31:0] instr_32
);
    wire [1:0] op = instr_c[1:0];
    wire [2:0] funct3 = instr_c[15:13];

    wire [4:0] rs1_c = {2'b01, instr_c[9:7]};
    wire [4:0] rs2_c = {2'b01, instr_c[4:2]};
    
    always @* begin
        case (op)
            2'b00: begin
                case (funct3)
                    3'b010: instr_32 = {{5'b0, instr_c[5], instr_c[12:10], instr_c[6], 2'b00}, rs1_c, 3'b010, rs2_c, 7'b0000011}; // c.lw
                    3'b110: instr_32 = {{5'b0, instr_c[5], instr_c[12]}, rs2_c, rs1_c, 3'b010, {instr_c[11:10], instr_c[6], 2'b00}, 7'b0100011}; // c.sw
                    default: instr_32 = 32'h00000013;
                endcase
            end
            
            2'b01: begin
                case (funct3)
                    3'b000: instr_32 = {{{6{instr_c[12]}}, instr_c[12], instr_c[6:2]}, instr_c[11:7], 3'b000, instr_c[11:7], 7'b0010011}; // c.addi
                    3'b001, 3'b101: // c.jal / c.j (BUG DE SALTO CORREGIDO)
                        instr_32 = {instr_c[12], instr_c[8], instr_c[10:9], instr_c[6], instr_c[7], instr_c[2], instr_c[11], instr_c[5:3], instr_c[12], {8{instr_c[12]}}, (funct3==3'b001 ? 5'b00001 : 5'b00000), 7'b1101111};
                    3'b010: instr_32 = {{{6{instr_c[12]}}, instr_c[12], instr_c[6:2]}, 5'b00000, 3'b000, instr_c[11:7], 7'b0010011}; // c.li
                    3'b011: begin
                        if (instr_c[11:7] == 5'b00010) // c.addi16sp (NUEVO PARA EL ÁRBOL)
                            instr_32 = {{{3{instr_c[12]}}, instr_c[12], instr_c[4:3], instr_c[5], instr_c[2], instr_c[6], 4'b0000}, 5'b00010, 3'b000, 5'b00010, 7'b0010011};
                        else // c.lui 
                            instr_32 = {{15{instr_c[12]}}, instr_c[6:2], instr_c[11:7], 7'b0110111};
                    end
                    3'b100: begin 
                        case (instr_c[11:10])
                            2'b00: instr_32 = {7'b0000000, instr_c[6:2], rs1_c, 3'b101, rs1_c, 7'b0010011}; // c.srli
                            2'b01: instr_32 = {7'b0100000, instr_c[6:2], rs1_c, 3'b101, rs1_c, 7'b0010011}; // c.srai
                            2'b10: instr_32 = {{{6{instr_c[12]}}, instr_c[12], instr_c[6:2]}, rs1_c, 3'b111, rs1_c, 7'b0010011}; // c.andi
                            2'b11: begin 
                                case (instr_c[6:5])
                                    2'b00: instr_32 = {7'b0100000, rs2_c, rs1_c, 3'b000, rs1_c, 7'b0110011}; // c.sub
                                    2'b01: instr_32 = {7'b0000000, rs2_c, rs1_c, 3'b100, rs1_c, 7'b0110011}; // c.xor
                                    2'b10: instr_32 = {7'b0000000, rs2_c, rs1_c, 3'b110, rs1_c, 7'b0110011}; // c.or
                                    2'b11: instr_32 = {7'b0000000, rs2_c, rs1_c, 3'b111, rs1_c, 7'b0110011}; // c.and
                                endcase
                            end
                        endcase
                    end
                    3'b110: instr_32 = {{{4{instr_c[12]}}, instr_c[6:5], instr_c[2]}, 5'b00000, rs1_c, 3'b000, {instr_c[11:10], instr_c[4:3], instr_c[12]}, 7'b1100011}; // c.beqz
                    3'b111: instr_32 = {{{4{instr_c[12]}}, instr_c[6:5], instr_c[2]}, 5'b00000, rs1_c, 3'b001, {instr_c[11:10], instr_c[4:3], instr_c[12]}, 7'b1100011}; // c.bnez
                    default: instr_32 = 32'h00000013;
                endcase
            end
            
            2'b10: begin
                case (funct3)
                    3'b000: instr_32 = {7'b0000000, instr_c[6:2], instr_c[11:7], 3'b001, instr_c[11:7], 7'b0010011}; // c.slli
                    3'b010: instr_32 = {{4'b0, instr_c[3:2], instr_c[12], instr_c[6:4], 2'b00}, 5'b00010, 3'b010, instr_c[11:7], 7'b0000011}; // c.lwsp
                    3'b100: begin
                        if (instr_c[12] == 0) begin
                            if (instr_c[6:2] == 0) // c.jr rs1
                                instr_32 = {12'b0, instr_c[11:7], 3'b000, 5'b00000, 7'b1100111};
                            else // c.mv
                                instr_32 = {7'b0000000, instr_c[6:2], 5'b00000, 3'b000, instr_c[11:7], 7'b0110011};
                        end else begin
                            if (instr_c[6:2] == 0) // c.jalr rs1
                                instr_32 = {12'b0, instr_c[11:7], 3'b000, 5'b00001, 7'b1100111};
                            else // c.add
                                instr_32 = {7'b0000000, instr_c[6:2], instr_c[11:7], 3'b000, instr_c[11:7], 7'b0110011};
                        end
                    end
                    3'b110: instr_32 = {{4'b0, instr_c[8:7], instr_c[12]}, instr_c[6:2], 5'b00010, 3'b010, {instr_c[11:9], 2'b00}, 7'b0100011}; // c.swsp
                    default: instr_32 = 32'h00000013;
                endcase
            end
            default: instr_32 = 32'h00000013; 
        endcase
    end
endmodule